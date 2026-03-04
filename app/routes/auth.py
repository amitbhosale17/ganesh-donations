"""
Authentication Routes Blueprint

Purpose:
- Handles user login and token refresh
- Validates credentials (email/phone + password)
- Issues JWT access and refresh tokens
- Returns user and tenant information on successful login

Security Flow:
1. User sends credentials (email/phone + password)
2. Server verifies credentials against database
3. Server generates JWT tokens (access + refresh)
4. Client stores tokens and uses access token for API requests
5. When access token expires, client uses refresh token to get new access token

JWT Tokens:
- Access Token: Short-lived (15 minutes), used for API authentication
- Refresh Token: Long-lived (30 days), used to get new access tokens
- Both are cryptographically signed to prevent tampering

Endpoints:
- POST /auth/login: Login with credentials
- POST /auth/refresh: Get new access token using refresh token
"""

# Import Flask utilities for routing and request/response handling
from flask import Blueprint, request, jsonify

# Import database cursor for querying users
from app.database import get_db_cursor

# Import authentication utilities (password verification, token creation)
from app.utils.auth import verify_password, create_access_token, create_refresh_token, decode_token

# Import application settings
from app.config import settings

# Create Blueprint for auth routes
# Blueprint groups related routes together
# url_prefix='/auth' means all routes here start with /auth
bp = Blueprint('auth', __name__, url_prefix='/auth')


@bp.route("/login", methods=["POST"])
def login():
    """
    User Login Endpoint
    
    Purpose:
    - Authenticates users with email/phone and password
    - Returns JWT tokens for subsequent API requests
    - Returns user and tenant information
    
    Request Body:
    {
        "identifier": "user@example.com" or "1234567890",  // Email or phone
        "password": "user_password"
    }
    
    Response (200 OK):
    {
        "accessToken": "eyJhbGciOiJIUzI1...",  // Short-lived token for API requests
        "refreshToken": "eyJhbGciOiJIUzI1...",  // Long-lived token for refreshing access token
        "user": { ...user details... },
        "tenant": { ...organization details... }
    }
    
    Error Responses:
    - 400: Missing identifier or password
    - 401: Invalid credentials (user not found or wrong password)
    - 500: Server error
    
    Security Features:
    - Supports login with email OR phone number
    - Password verification using secure hashing
    - Only allows login for ACTIVE users
    - Returns tenant information for multi-tenant context
    """
    
    try:
        # Step 1: Extract login credentials from request body
        data = request.get_json()
        identifier = data.get('identifier')  # Email or phone number
        password = data.get('password')
        
        # Step 2: Validate that both fields are provided
        if not identifier or not password:
            return jsonify({"error": "Missing identifier or password"}), 400
        
        # Step 3: Query database to find user by email or phone
        with get_db_cursor() as cursor:
            # Complex JOIN query to get user and tenant data in one query
            # Joins User table with Tenant table to get organization info
            cursor.execute("""
                SELECT 
                    u.id, u.tenant_id, u.name, u.email, u.phone, u.role, u.password_hash, u.status,
                    t.name as tenant_name, t.logo_url, t.upi_qr_url, t.receipt_prefix, 
                    t.footer_lines, t.locale_default, t.address, t.contact_phone,
                    t.president_name, t.vice_president_name, t.secretary_name, t.treasurer_name,
                    t.registration_no, t.footer_text
                FROM "User" u
                JOIN Tenant t ON u.tenant_id = t.id
                WHERE (u.email = %s OR u.phone = %s) AND u.status = 'ACTIVE'
                LIMIT 1
            """, (identifier, identifier))  # Pass identifier twice for email OR phone check
            
            # Fetch user record
            user = cursor.fetchone()
            
            # Step 4: Check if user exists
            if not user:
                # Return generic error (don't reveal if email exists for security)
                return jsonify({"error": "Invalid credentials"}), 401
            
            # Step 5: Verify password
            # verify_password compares plain password with hashed password from database
            if not verify_password(password, user['password_hash']):
                # Return same error as above (don't reveal which field is wrong)
                return jsonify({"error": "Invalid credentials"}), 401
            
            # Step 6: Generate JWT tokens
            # Token payload contains user identity and authorization info
            token_data = {
                "id": user['id'],
                "tenant_id": user['tenant_id'],
                "role": user['role'],
                "name": user['name']
            }
            
            # Create access token (short-lived, used for API requests)
            access_token = create_access_token(token_data)
            
            # Create refresh token (long-lived, used to get new access tokens)
            refresh_token = create_refresh_token(token_data)
            
            # Step 7: Return success response with tokens and user/tenant data
            return jsonify({
                "accessToken": access_token,
                "refreshToken": refresh_token,
                # User information for frontend display
                "user": {
                    "id": user['id'],
                    "name": user['name'],
                    "email": user['email'],
                    "phone": user['phone'],
                    "role": user['role'],
                    "tenant_id": user['tenant_id']
                },
                # Tenant (organization) information for branding and configuration
                "tenant": {
                    "id": user['tenant_id'],
                    "name": user['tenant_name'],
                    "logo_url": user['logo_url'],  # Organization logo
                    "upi_qr_url": user['upi_qr_url'],  # UPI QR code for donations
                    "receipt_prefix": user['receipt_prefix'],  # Prefix for receipt numbers
                    "footer_lines": user['footer_lines'],  # Custom footer for receipts
                    "locale_default": user['locale_default'],  # Language preference
                    "address": user['address'],
                    "contact_phone": user['contact_phone'],
                    "president_name": user['president_name'],  # Organization officials
                    "vice_president_name": user['vice_president_name'],
                    "secretary_name": user['secretary_name'],
                    "treasurer_name": user['treasurer_name'],
                    "registration_no": user['registration_no'],  # Legal registration number
                    "footer_text": user['footer_text']
                }
            })
            
    except Exception as e:
        # Log error with full stack trace for debugging
        import traceback
        print(f"Login error: {str(e)}")
        print(traceback.format_exc())
        return jsonify({"error": str(e)}), 500


@bp.route("/refresh", methods=["POST"])
def refresh():
    """
    Refresh Access Token Endpoint
    
    Purpose:
    - Issues a new access token using a valid refresh token
    - Allows users to stay logged in without re-entering password
    - Extends session when access token expires
    
    Why Refresh Tokens?
    - Access tokens expire quickly (15 minutes) for security
    - Refresh tokens last longer (30 days) for convenience
    - If access token is stolen, damage is limited (expires soon)
    - User only needs to login with password every 30 days
    
    Request Body:
    {
        "refreshToken": "eyJhbGciOiJIUzI1..."  // The refresh token from login
    }
    
    Response (200 OK):
    {
        "accessToken": "eyJhbGciOiJIUzI1..."  // New access token
    }
    
    Error Responses:
    - 400: Missing refresh token
    - 401: Invalid or expired refresh token
    
    Security:
    - Validates refresh token signature and expiration
    - Does not generate new refresh token (use original until it expires)
    - Client must re-login with password after refresh token expires
    """
    
    # Step 1: Extract refresh token from request body
    data = request.get_json()
    refresh_token = data.get('refreshToken')
    
    # Step 2: Validate refresh token is provided
    if not refresh_token:
        return jsonify({"detail": "Missing refresh token"}), 400
    
    # Step 3: Decode and validate refresh token
    # decode_token verifies signature and expiration
    # Returns None if invalid or expired
    payload = decode_token(refresh_token, settings.REFRESH_SECRET)
    
    # Step 4: Check if token is valid
    if payload is None:
        return jsonify({"detail": "Invalid refresh token"}), 401
    
    # Step 5: Generate new access token with same user data
    # Extract user identity from refresh token payload
    token_data = {
        "id": payload['id'],
        "tenant_id": payload['tenant_id'],
        "role": payload['role'],
        "name": payload['name']
    }
    
    # Create new access token (extends session for another 15 minutes)
    access_token = create_access_token(token_data)
    
    # Step 6: Return new access token
    # Note: Refresh token remains unchanged and reusable until it expires
    return jsonify({"accessToken": access_token})
