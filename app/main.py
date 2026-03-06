"""
Flask Application Main Module

Purpose:
- Central entry point for the Flask web application
- Sets up all application components and configuration
- Registers API routes (blueprints)
- Configures CORS, database, logging
- Runs database migrations on startup

Architecture:
- Flask: Web framework for handling HTTP requests
- Blueprints: Modular organization of routes (auth, donations, users, etc.)
- CORS: Allow cross-origin requests from frontend (Flutter app)
- Database Pool: Reusable PostgreSQL connections
- Migrations: Auto-apply schema changes on startup

Startup Sequence:
1. Configure logging
2. Create Flask app
3. Setup CORS
4. Run database migrations
5. Initialize database pool
6. Register route blueprints
7. Setup error handlers
8. Ready to serve requests
"""

# ============================================
# FLASK AND WEB FRAMEWORK IMPORTS
# ============================================
# Flask: Core web framework
from flask import Flask, jsonify, send_from_directory
# CORS: Cross-Origin Resource Sharing (allows frontend to call API from different domain)
from flask_cors import CORS
# Logging: Record errors and info messages
import logging
# Path: Object-oriented file path manipulation
from pathlib import Path
# atexit: Register cleanup functions to run when app exits
import atexit

# ============================================
# APPLICATION MODULES
# ============================================
# Import configuration settings (database URL, JWT secrets, etc.)
from app.config import settings
# Import database connection pool management
from app.database import init_db_pool, close_db_pool
# Import all route blueprints (modular API endpoints)
from app.routes import auth, tenant, donations, superadmin, stats, users, reports, categories, donors, subscriptions, events

# ============================================
# LOGGING CONFIGURATION
# ============================================
# Configure logging to show timestamps, logger name, level, and message
# Level INFO: Shows INFO, WARNING, ERROR, CRITICAL (but not DEBUG)
# Format example: "2024-01-15 10:30:45 - app.main - INFO - Server started"
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
# Create logger for this module
logger = logging.getLogger(__name__)

# ============================================
# CREATE FLASK APPLICATION
# ============================================
# Create the Flask app instance
# __name__ tells Flask where to find templates, static files, etc.
app = Flask(__name__)

# ============================================
# CORS (Cross-Origin Resource Sharing) CONFIGURATION
# ============================================
# CORS is needed because:
# - Frontend (Flutter app) runs on different domain/port than API
# - Browsers block cross-origin requests by default for security
# - We explicitly allow it here
#
# Configuration breakdown:
# - r"/*": Apply CORS to all routes
# - origins: "*" = allow requests from any domain (for development)
# - methods: Allow GET, POST, PUT, DELETE, OPTIONS HTTP methods
# - allow_headers: Which headers frontend can send
# - expose_headers: Which headers frontend can read from response
# - supports_credentials: False = don't send cookies (we use JWT instead)
# - max_age: How long browser can cache CORS preflight response (1 hour)
CORS(app, resources={
    r"/*": {
        "origins": "*",  # TODO: In production, restrict to specific domains
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"],
        "expose_headers": ["Content-Type", "Authorization"],
        "supports_credentials": False,
        "max_age": 3600
    }
})

# ============================================
# DATABASE MIGRATION SYSTEM
# ============================================
def run_migrations_on_startup():
    """
    Run database migrations when app starts
    
    Purpose:
    - Automatically update database schema to match application code
    - Creates tables, columns, indexes, default data
    - Safe to run multiple times (idempotent)
    
    How Migrations Work:
    1. Migration files are stored in migrations/ directory
    2. Named with numbers for ordering: 001_init.sql, 002_add_column.sql
    3. Each file contains SQL commands (CREATE TABLE, ALTER TABLE, etc.)
    4. System executes them in order on startup
    5. Already-applied migrations are skipped (based on error messages)
    
    Why Migrations?
    - Database schema evolves as app develops
    - Migrations track schema changes over time
    - Easy to deploy updates (just add new migration file)
    - Prevents manual SQL errors
    """
    # Import required modules
    import glob  # For finding .sql files
    import os    # For file operations
    import psycopg  # For database connection
    
    try:
        # Log migration start
        logger.info("🔄 Running database migrations...")
        
        # Step 1: Find all SQL files in migrations/ directory
        # glob.glob returns list of matching file paths
        # sorted() ensures they run in alphabetical/numerical order
        migration_files = sorted(glob.glob('migrations/*.sql'))
        
        # Step 2: Connect to database and execute each migration
        with psycopg.connect(settings.DATABASE_URL) as conn:
            with conn.cursor() as cur:
                # Loop through each migration file
                for migration_file in migration_files:
                    try:
                        # Log which migration is running
                        logger.info(f"   Executing {os.path.basename(migration_file)}...")
                        
                        # Step 3: Read SQL content from file
                        with open(migration_file, 'r', encoding='utf-8') as f:
                            migration_sql = f.read()
                        
                        # Step 4: Execute the SQL
                        cur.execute(migration_sql)
                        
                        # Step 5: Commit to make changes permanent
                        conn.commit()
                        
                        # Log success
                        logger.info(f"   ✓ {os.path.basename(migration_file)} done")
                        
                    except Exception as e:
                        # Error handling: Check if migration was already applied
                        # PostgreSQL returns "already exists" or "duplicate" for existing objects
                        if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                            # This is normal - migration was run before
                            logger.info(f"   ℹ️  {os.path.basename(migration_file)} already applied")
                            conn.rollback()  # Clear failed transaction
                        else:
                            # Unexpected error - log but continue with next migration
                            logger.warning(f"   ⚠️  {os.path.basename(migration_file)} error: {e}")
                            conn.rollback()  # Clear failed transaction
        
        # All migrations processed
        logger.info("✅ All migrations completed!")
        
    except Exception as e:
        # Catch-all for unexpected errors
        logger.error(f"⚠️  Migration error: {e}")

# ============================================
# RUN MIGRATIONS IMMEDIATELY ON STARTUP
# ============================================
# Execute migrations now (before database pool is initialized)
# This ensures schema is up-to-date before any queries run
try:
    run_migrations_on_startup()
except Exception as e:
    # Log error but don't stop app (allows debugging even with migration failures)
    logger.error(f"Failed to run migrations: {e}")

# Run auto-migration for ReceiptSequence table (hotfix)
try:
    import sys
    import os
    # Add parent directory to path so we can import run_migration_auto
    sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    from run_migration_auto import run_migration
    run_migration()
except Exception as e:
    logger.warning(f"Auto-migration warning: {e}")

# ============================================
# INITIALIZE DATABASE CONNECTION POOL
# ============================================
logger.info("🚀 Starting Ganesh Donations API...")

try:
    # Create connection pool (see database.py for details)
    # This must happen after migrations but before registering routes
    init_db_pool()
    logger.info("✅ Database connection pool ready")
    
except Exception as e:
    # Log error but continue (allows server to start for debugging)
    logger.error(f"❌ Database initialization failed: {e}")
    logger.warning("⚠️ Server will start but database operations will fail")

# ============================================
# CREATE UPLOADS DIRECTORY
# ============================================
# Create directory for storing uploaded files (logos, UPI QR codes, receipts)
# Path.resolve() converts to absolute path
# mkdir(exist_ok=True) creates directory if it doesn't exist (no error if it does)
upload_dir = Path(settings.UPLOAD_DIR).resolve()
upload_dir.mkdir(exist_ok=True)

logger.info(f"📁 Uploads directory: {upload_dir}")

# ============================================
# REGISTER CLEANUP ON SHUTDOWN
# ============================================
# Register close_db_pool to be called when app exits
# This ensures database connections are properly closed
# Prevents connection leaks and allows graceful shutdown
atexit.register(close_db_pool)

# ============================================
# STATIC FILES ROUTE FOR UPLOADS
# ============================================
@app.route('/uploads/<path:filename>')
def uploaded_file(filename):
    """
    Serve uploaded files
    
    Purpose:
    - Makes uploaded files accessible via HTTP
    - Returns files from uploads/ directory
    
    Example:
    - File stored as: uploads/logo_123.png
    - Accessible at: http://localhost:8080/uploads/logo_123.png
    
    Security Note:
    - Flask's send_from_directory validates filename to prevent directory traversal attacks
    - Users cannot access files outside uploads/ directory
    
    Edge Cases Handled:
    - Upload directory doesn't exist
    - File doesn't exist (404)
    - Directory traversal attempts
    - Requested path is a directory, not a file
    - File permissions issues
    """
    # Log file access for monitoring
    logger.info(f"📥 File request: {filename}")
    
    # EDGE CASE 1: Check if uploads directory exists
    if not upload_dir.exists():
        logger.error(f"❌ Uploads directory not found: {upload_dir}")
        return {"error": "Upload directory not configured"}, 500
    
    # EDGE CASE 2: Build full file path and check if it exists
    file_path = upload_dir / filename
    if not file_path.exists():
        logger.warning(f"⚠️  File not found: {filename}")
        return {"error": "File not found"}, 404
    
    # EDGE CASE 3: Ensure it's a file, not a directory
    if not file_path.is_file():
        logger.warning(f"⚠️  Requested path is not a file: {filename}")
        return {"error": "Invalid file"}, 400
    
    try:
        # Get file size for logging
        file_size = file_path.stat().st_size
        file_size_mb = file_size / (1024 * 1024)
        
        # Send file from uploads directory
        # send_from_directory handles content-type, caching headers, etc.
        logger.info(f"✅ Serving file: {filename} ({file_size_mb:.2f} MB)")
        return send_from_directory(str(upload_dir), filename)
        
    except PermissionError as e:
        # EDGE CASE 4: File exists but no read permission
        logger.error(f"❌ Permission denied reading file {filename}: {e}")
        return {"error": "Cannot access file"}, 500
        
    except Exception as e:
        # EDGE CASE 5: Other unexpected errors
        logger.error(f"❌ Error serving file {filename}: {e}")
        return {"error": "Failed to serve file"}, 500

# ============================================
# REGISTER ROUTE BLUEPRINTS
# ============================================
# Blueprints organize routes into modules
# Each blueprint handles related functionality
# Example: auth.bp has /auth/login, /auth/refresh, etc.

# Authentication: Login, logout, token refresh
app.register_blueprint(auth.bp)

# Tenant Management: Manage organization settings, logos, UPI codes
app.register_blueprint(tenant.bp)

# Donations: Create, read, update donations
app.register_blueprint(donations.bp)

# SuperAdmin: System-wide administration functions
app.register_blueprint(superadmin.bp)

# Statistics: Dashboard data, analytics
app.register_blueprint(stats.bp)

# User Management: CRUD operations for users
app.register_blueprint(users.users_bp)

# Reports: Generate and export reports
app.register_blueprint(reports.reports_bp)

# Categories: Donation category management
app.register_blueprint(categories.categories_bp)

# Donors: Donor information management
app.register_blueprint(donors.donors_bp)

# Subscriptions: Multi-year subscription management
app.register_blueprint(subscriptions.bp)

# Events: Event types and organization events
app.register_blueprint(events.bp)

# ============================================
# CORS HEADERS MIDDLEWARE
# ============================================
# Add CORS headers to all responses
# This is redundant with flask_cors above but ensures headers are present
# after_request decorator runs after route handler but before sending response
@app.after_request
def after_request(response):
    """
    Add CORS headers to every response
    
    Purpose:
    - Ensures CORS headers are present on all responses
    - Redundant with flask_cors configuration but provides extra safety
    - Handles edge cases where flask_cors might not add headers
    
    Headers Added:
    - Access-Control-Allow-Origin: Which domains can access API
    - Access-Control-Allow-Methods: Which HTTP methods are allowed
    - Access-Control-Allow-Headers: Which headers can be sent
    - Access-Control-Max-Age: How long to cache preflight response
    """
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With'
    response.headers['Access-Control-Max-Age'] = '3600'
    return response

# ============================================
# HEALTH CHECK ENDPOINT
# ============================================
@app.route("/health")
def health_check():
    """
    Health check endpoint
    
    Purpose:
    - Allows monitoring systems to check if API is running
    - Used by load balancers, container orchestration (Kubernetes), monitoring tools
    - Returns simple OK status
    
    Returns:
    - 200 OK with {"status": "ok"} if server is running
    - 500 Error if something is wrong
    
    Usage:
    - Monitoring: curl http://localhost:8080/health
    - Load Balancer: Periodically checks this endpoint
    - Container Orchestration: Kubernetes liveness/readiness probes
    """
    try:
        # Return simple OK response
        return jsonify({
            "status": "ok",
            "service": "Ganesh Donations API"
        })
    except Exception as e:
        # Log error for debugging
        logger.error(f"Health check error: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

# ============================================
# DEBUG ENDPOINTS (For Development Only)
# ============================================
# These endpoints help debug database issues during development
# TODO: Remove or secure these in production

@app.route("/debug/users")
def debug_users():
    """
    Debug endpoint to inspect users table
    
    Purpose:
    - View users in database for debugging
    - Check password hashes, roles, tenant assignments
    - Troubleshoot login issues
    
    Security:
    - Exposes password hashes and sensitive data
    - Should be removed or secured in production
    
    Returns:
    - List of first 10 users with all fields
    """
    try:
        # Import database cursor function
        from app.database import get_db_cursor
        
        # Query users table
        with get_db_cursor() as cur:
            # Select important user fields
            # "User" in quotes because User is a reserved word in PostgreSQL
            cur.execute('SELECT id, name, email, phone, role, status, password_hash, tenant_id FROM "User" LIMIT 10')
            users = cur.fetchall()  # Fetch all results as list of dicts
            
            # Return count and user data
            return jsonify({"count": len(users), "users": users})
            
    except Exception as e:
        # Return error details
        return jsonify({"error": str(e)}), 500

@app.route("/debug/tenants")
def debug_tenants():
    """
    Debug endpoint to inspect tenants table
    
    Purpose:
    - View organizations/tenants in database
    - Check tenant configuration
    - Troubleshoot multi-tenant issues
    
    Returns:
    - List of first 10 tenants
    """
    try:
        from app.database import get_db_cursor
        
        # Query tenants table
        with get_db_cursor() as cur:
            cur.execute('SELECT id, name, address, receipt_prefix FROM Tenant LIMIT 10')
            tenants = cur.fetchall()
            
            return jsonify({"count": len(tenants), "tenants": tenants})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/debug/fix-users", methods=["POST"])
def fix_users():
    """
    Fix users with invalid tenant_id (Debug/Maintenance Endpoint)
    
    Purpose:
    - Repairs data integrity issues with user-tenant relationships
    - Sets orphaned users (without valid tenant) to system tenant (id=0)
    
    When to Use:
    - After manual database changes
    - If tenant deletion left orphaned users
    - Data migration issues
    
    What It Does:
    - Finds users with NULL tenant_id
    - Finds users with tenant_id pointing to non-existent tenants
    - Updates them to tenant_id = 0 (system tenant)
    
    Returns:
    - Number of users fixed
    """
    try:
        from app.database import get_db_cursor
        
        # Execute update query with commit
        with get_db_cursor(commit=True) as cur:
            # Update users with invalid tenant references
            # tenant_id = 0 is the system/superadmin tenant
            cur.execute('''
                UPDATE "User" 
                SET tenant_id = 0 
                WHERE tenant_id IS NULL 
                   OR tenant_id NOT IN (SELECT id FROM Tenant)
            ''')
            
            # Get number of rows affected
            affected = cur.rowcount
            
            return jsonify({"message": f"Fixed {affected} users", "success": True})
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/create-superadmin", methods=["POST"])
def create_superadmin():
    """
    Create or update SuperAdmin user (Setup/Debug Endpoint)
    
    Purpose:
    - Creates the initial SuperAdmin account for system administration
    - Updates existing SuperAdmin if password needs reset
    - Used during initial setup or password recovery
    
    SuperAdmin Credentials:
    - Email: superadmin@system.local
    - Password: Super@123
    - Role: SUPERADMIN (highest privilege level)
    - Tenant: 0 (system tenant)
    
    What It Does:
    1. Creates system tenant (id=0) if not exists
    2. Checks if SuperAdmin user exists
    3. Creates new user or updates existing one
    4. Hashes password with bcrypt (secure one-way hashing)
    5. Returns credentials for login
    
    Security Notes:
    - Password is hashed before storing (never store plain text passwords)
    - bcrypt is slow by design (prevents brute force attacks)
    - SuperAdmin has unrestricted access to all data
    
    TODO:
    - Disable this endpoint in production
    - Or require authentication to access it
    """
    try:
        # Import required modules
        from app.database import get_db_cursor
        from passlib.hash import bcrypt  # Password hashing library
        
        # Set SuperAdmin password
        password = "Super@123"
        
        # Hash the password using bcrypt
        # bcrypt is a slow hashing algorithm designed for passwords
        # It includes salt (random data) automatically
        # Even if two users have same password, hashes will differ
        password_hash = bcrypt.hash(password)
        
        # Execute database operations
        with get_db_cursor() as cur:
            # Step 1: Create system tenant (id=0) if it doesn't exist
            # This tenant is used for system-level users like SuperAdmin
            # ON CONFLICT DO NOTHING: Skip if already exists
            cur.execute("""
                INSERT INTO Tenant (id, name, address, receipt_prefix) 
                VALUES (0, 'System Admin', 'System', 'SYS')
                ON CONFLICT (id) DO NOTHING
            """)
            
            # Step 2: Check if SuperAdmin user already exists
            cur.execute("SELECT id FROM \"User\" WHERE email = 'superadmin@system.local'")
            existing = cur.fetchone()
            
            if existing:
                # SuperAdmin exists - update with new password
                cur.execute("""
                    UPDATE "User" 
                    SET password_hash = %s, role = 'SUPERADMIN', status = 'ACTIVE', name = 'Super Admin', tenant_id = 0
                    WHERE email = 'superadmin@system.local'
                """, (password_hash,))
                message = "SuperAdmin user updated with new password"
            else:
                # SuperAdmin doesn't exist - create new user
                cur.execute("""
                    INSERT INTO "User" (tenant_id, name, email, role, password_hash, status)
                    VALUES (0, 'Super Admin', 'superadmin@system.local', 'SUPERADMIN', %s, 'ACTIVE')
                """, (password_hash,))
                message = "SuperAdmin user created successfully"
            
            # Step 3: Verify user was created/updated correctly
            cur.execute("SELECT id, name, email, role FROM \"User\" WHERE email = 'superadmin@system.local'")
            user = cur.fetchone()
            
            # Return success response with user info and credentials
            return jsonify({
                "success": True,
                "message": message,
                "user": {
                    "id": user[0],
                    "name": user[1],
                    "email": user[2],
                    "role": user[3]
                },
                "credentials": {
                    "email": "superadmin@system.local",
                    "password": "Super@123"
                }
            })
            
    except Exception as e:
        # Log error with full stack trace for debugging
        logger.error(f"Error creating superadmin: {e}", exc_info=True)
        return jsonify({"error": str(e)}), 500

# ============================================
# TEST ENDPOINT
# ============================================
@app.route("/test")
def test():
    """
    Simple test endpoint
    
    Purpose:
    - Quick health check that returns plain text (not JSON)
    - Useful for testing if server is responding
    - Minimal processing overhead
    
    Returns:
    - Plain text "OK" with 200 status code
    """
    # Return plain text response (not JSON)
    # Format: (body, status_code, headers)
    return "OK", 200, {'Content-Type': 'text/plain'}

# ============================================
# GLOBAL ERROR HANDLER
# ============================================
@app.errorhandler(Exception)
def handle_error(error):
    """
    Global error handler for uncaught exceptions
    
    Purpose:
    - Catches any unhandled exceptions in the application
    - Prevents exposing internal error details to users (in production)
    - Logs error with full stack trace for debugging
    - Returns consistent error response format
    
    Why This Matters:
    - Without this, Flask shows default error page with stack trace
    - Stack traces can expose sensitive information (file paths, database structure)
    - Consistent error format makes it easier for frontend to handle errors
    
    Parameters:
    - error: The exception that was raised
    
    Returns:
    - JSON response with error message and type
    - 500 Internal Server Error status code
    """
    # Log error with full stack trace
    # exc_info=True includes the traceback in the log
    logger.error(f"Unhandled error: {error}", exc_info=True)
    
    # Return user-friendly error response
    return jsonify({
        "error": str(error),  # Error message
        "type": type(error).__name__  # Error class name (e.g., "ValueError")
    }), 500  # HTTP 500 = Internal Server Error

# ============================================
# ROOT ENDPOINT
# ============================================
@app.route("/")
def root():
    """
    Root endpoint - API welcome message
    
    Purpose:
    - Provides basic API information
    - Confirms API is running
    - Points to health check endpoint
    
    Usage:
    - Browser: Navigate to http://localhost:8080/
    - Shows API is accessible
    - Provides version and health check URL
    
    Returns:
    - Welcome message with API name and version
    - Link to /health endpoint
    """
    try:
        # Log access for monitoring
        logger.info(f"Root endpoint accessed")
        
        # Prepare response data
        response = {
            "message": "🕉️ Ganesh Donations API",
            "version": "1.0.0",
            "health": "/health"  # URL for health check
        }
        
        # Log response for debugging
        logger.info(f"Returning response: {response}")
        
        # Return JSON response
        return jsonify(response)
        
    except Exception as e:
        # Log error and re-raise (will be caught by global error handler)
        logger.error(f"Error in root endpoint: {e}", exc_info=True)
        raise

# ============================================
# DEVELOPMENT SERVER (Not Used in Production)
# ============================================
# This code only runs when executing: python app/main.py directly
# In production, we use server.py with Waitress instead
if __name__ == "__main__":
    # Display startup banner with server information
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🕉️  Ganesh Donations API Server (Python/Flask)         ║
║                                                           ║
║   Status: ✅ RUNNING                                      ║
║   Port: {}                                             ║
║   Environment: development                                ║
║                                                           ║
║   Endpoints:                                              ║
║   - POST   /auth/login                                    ║
║   - POST   /auth/refresh                                  ║
║   - GET    /tenant/self                                   ║
║   - PUT    /tenant/self                                   ║
║   - POST   /tenant/upload/logo                            ║
║   - POST   /tenant/upload/upi_qr                          ║
║   - GET    /users                                         ║
║   - POST   /users                                         ║
║   - POST   /donations                                     ║
║   - GET    /donations                                     ║
║   - GET    /donations/stats                               ║
║   - GET    /donations/export.csv                          ║
║                                                           ║
║   गणपती बाप्पा मोरया! 🙏                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """.format(settings.PORT))
    
    # Start Flask development server
    # WARNING: This is Flask's built-in development server
    # NOT suitable for production (slow, single-threaded, security issues)
    # Use server.py with Waitress for production
    app.run(
        host="0.0.0.0",  # Listen on all network interfaces
        port=settings.PORT,  # Port from configuration
        debug=False  # Set to True for auto-reload and better error messages during development
        # debug=True: Auto-reloads on code changes, shows interactive debugger
        # debug=False: Better for stability, no auto-reload
    )
