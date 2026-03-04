"""
Authentication Middleware

Purpose:
- Provides decorators for route protection
- Validates JWT tokens from request headers
- Enforces role-based access control (RBAC)
- Extracts user information from tokens

Decorators Provided:
1. @require_auth: Requires valid JWT token (any authenticated user)
2. @require_admin: Requires ADMIN or SUPERADMIN role
3. @require_superadmin: Requires SUPERADMIN role only

Usage Example:
    from app.middleware.auth import require_auth, require_admin
    
    @app.route("/protected")
    @require_auth
    def protected_route(user):
        # user parameter contains decoded token data
        return {"message": f"Hello {user['name']}"}
    
    @app.route("/admin-only")
    @require_admin
    def admin_route(user):
        # Only ADMIN and SUPERADMIN can access
        return {"admin_data": "..."}

How It Works:
1. Client sends request with Authorization header: "Bearer <token>"
2. Decorator extracts and validates token
3. If valid, user data is passed to route handler
4. If invalid/missing, returns 401 Unauthorized
5. If insufficient role, returns 403 Forbidden
"""

# Import Flask request object to access headers
from flask import request, jsonify
# Import functools.wraps to preserve function metadata in decorators
from functools import wraps
# Import token decoding utility
from app.utils.auth import decode_token
# Import application settings
from app.config import settings


def get_current_user():
    """
    Validate JWT token and return user data
    
    Purpose:
    - Extracts JWT token from Authorization header
    - Validates token signature and expiration
    - Returns decoded user data from token
    
    Authorization Header Format:
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
    
    Returns:
    - dict: User data (id, tenant_id, role, name) if token is valid
    - None: If token is missing, malformed, or invalid
    
    Token Validation:
    - Checks cryptographic signature (prevents tampering)
    - Checks expiration time (exp claim)
    - Uses JWT_SECRET from settings
    """
    # Step 1: Get Authorization header from request
    # Example: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    auth_header = request.headers.get('Authorization')
    
    # Step 2: Validate header format
    # Must be present and start with "Bearer "
    if not auth_header or not auth_header.startswith('Bearer '):
        return None
    
    # Step 3: Extract token part (remove "Bearer " prefix)
    # Split by space and take second part
    token = auth_header.split(' ')[1]
    
    # Step 4: Decode and validate token
    # decode_token verifies signature and expiration
    # Returns None if invalid
    payload = decode_token(token, settings.JWT_SECRET)
    
    # Step 5: Return user data from token payload
    return payload


def require_auth(f):
    """
    Decorator to require authentication
    
    Purpose:
    - Protects routes that require user to be logged in
    - Validates JWT token on every request
    - Passes user data to route handler
    
    Usage:
        @app.route("/profile")
        @require_auth
        def get_profile(user):
            return {"name": user["name"]}
    
    How Decorators Work:
    - Wraps the original function with authentication logic
    - Executes before the route handler
    - Can block request or pass it through
    
    Parameters:
    - f: The route handler function to protect
    
    Returns:
    - Decorated function that checks authentication first
    - 401 Unauthorized if token is invalid/missing
    - Calls original function with user parameter if valid
    """
    # @wraps(f) preserves original function's metadata (name, docstring, etc.)
    # Without this, all decorated functions would appear to be named "decorated_function"
    @wraps(f)
    def decorated_function(*args, **kwargs):
        """
        Inner function that performs authentication check
        
        Process:
        1. Get current user from token
        2. If no user (invalid/missing token), return 401
        3. If valid, call original function with user parameter
        """
        # Validate token and get user data
        user = get_current_user()
        
        # Check if authentication succeeded
        if user is None:
            # Token missing or invalid - deny access
            return jsonify({"detail": "Invalid or expired token"}), 401
        
        # Token valid - proceed to route handler
        # Pass user data as keyword argument
        return f(user=user, *args, **kwargs)
    
    return decorated_function


def require_admin(f):
    """
    Decorator to require admin role (ADMIN or SUPERADMIN)
    
    Purpose:
    - Protects routes that require administrative privileges
    - Validates both authentication AND authorization
    - Allows ADMIN and SUPERADMIN roles only
    
    Role Hierarchy:
    - VOLUNTEER: Basic user (cannot access admin routes)
    - ADMIN: Organization administrator
    - SUPERADMIN: System administrator (highest privileges)
    
    Usage:
        @app.route("/admin/users")
        @require_admin
        def list_users(user):
            # Only ADMIN and SUPERADMIN can access
            return {"users": [...]}
    
    Returns:
    - 401 Unauthorized if token is invalid/missing
    - 403 Forbidden if user role is not ADMIN or SUPERADMIN
    - Calls original function if authorized
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        """
        Inner function that checks authentication AND role
        
        Process:
        1. Validate token (authentication)
        2. Check if role is ADMIN or SUPERADMIN (authorization)
        3. Return 401 if not authenticated, 403 if not authorized
        """
        # Step 1: Validate token and get user data
        user = get_current_user()
        
        # Step 2: Check authentication
        if user is None:
            return jsonify({"detail": "Invalid or expired token"}), 401
        
        # Step 3: Check authorization (role-based access control)
        # user.get("role") safely gets role, returns None if key doesn't exist
        if user.get("role") not in ["ADMIN", "SUPERADMIN"]:
            # User is authenticated but doesn't have admin role
            return jsonify({"detail": "Admin access required"}), 403
        
        # Step 4: User is authenticated AND authorized - proceed
        return f(user=user, *args, **kwargs)
    
    return decorated_function


def require_superadmin(f):
    """
    Decorator to require SUPERADMIN role
    
    Purpose:
    - Protects system-level administrative routes
    - Highest level of access control
    - Only SUPERADMIN role can access
    
    SuperAdmin Capabilities:
    - Manage multiple tenants/organizations
    - Create and delete organizations
    - Access all organizations' data
    - System configuration and maintenance
    
    Usage:
        @app.route("/superadmin/tenants")
        @require_superadmin
        def manage_tenants(user):
            # Only SUPERADMIN can access
            return {"tenants": [...]}
    
    Security:
    - Strictest access control decorator
    - ADMIN users are denied (even though they are admins)
    - Only SUPERADMIN role has system-wide access
    
    Returns:
    - 401 Unauthorized if token is invalid/missing
    - 403 Forbidden if user role is not SUPERADMIN
    - Calls original function if authorized
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        """
        Inner function that enforces SUPERADMIN-only access
        
        Process:
        1. Validate token (authentication)
        2. Check if role is exactly SUPERADMIN
        3. Deny access if role is anything else (even ADMIN)
        """
        # Step 1: Validate token and get user data
        user = get_current_user()
        
        # Step 2: Check authentication
        if user is None:
            return jsonify({"detail": "Invalid or expired token"}), 401
        
        # Step 3: Check for SUPERADMIN role specifically
        # Note: Uses != instead of "not in" - only SUPERADMIN allowed, not ADMIN
        if user.get("role") != "SUPERADMIN":
            # Even ADMINs are denied access to superadmin routes
            return jsonify({"detail": "SuperAdmin access required"}), 403
        
        # Step 4: User is SUPERADMIN - proceed
        return f(user=user, *args, **kwargs)
    
    return decorated_function


def require_collector(f):
    """
    Decorator to require COLLECTOR role (or higher)
    
    Purpose:
    - Protects donation collection routes
    - Allows COLLECTOR, ADMIN, and SUPERADMIN roles
    - Prevents VOLUNTEER role from collecting donations
    
    Role Hierarchy for Donation Collection:
    - VOLUNTEER: Cannot collect donations (view-only)
    - COLLECTOR: Can collect and record donations
    - ADMIN: Can collect + manage organization
    - SUPERADMIN: Can collect + manage all organizations
    
    Collector Responsibilities:
    - Record donations from donors
    - Generate receipts
    - Handle cash/online payments
    - Track donation statistics
    
    Usage:
        @app.route("/donations", methods=["POST"])
        @require_collector
        def create_donation(user):
            # COLLECTOR, ADMIN, SUPERADMIN can access
            return {"donation_id": 123}
    
    Returns:
    - 401 Unauthorized if token is invalid/missing
    - 403 Forbidden if user role is VOLUNTEER
    - Calls original function if role is COLLECTOR or higher
    """
    @wraps(f)
    def decorated_function(*args, **kwargs):
        """
        Inner function that checks for collector-level access
        
        Process:
        1. Validate token (authentication)
        2. Check if role is COLLECTOR, ADMIN, or SUPERADMIN
        3. Deny access to VOLUNTEERs and unauthenticated users
        """
        # Step 1: Validate token and get user data
        user = get_current_user()
        
        # Step 2: Check authentication
        if user is None:
            return jsonify({"detail": "Invalid or expired token"}), 401
        
        # Step 3: Check if user has collector-level access
        # Allows COLLECTOR (donation collector), ADMIN, and SUPERADMIN
        # Denies VOLUNTEER (read-only role)
        if user.get("role") not in ["ADMIN", "COLLECTOR", "SUPERADMIN"]:
            return jsonify({"detail": "Collector or Admin access required"}), 403
        
        # Step 4: User has sufficient privileges - proceed
        return f(user=user, *args, **kwargs)
    
    return decorated_function
