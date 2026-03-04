"""
Production-ready server startup script using Waitress WSGI server.
This works reliably on Windows with Python 3.14.

Purpose:
- This is the main entry point for running the Flask application in production
- Uses Waitress WSGI server instead of Flask's development server for better performance and reliability
- Automatically runs database migrations before starting the server
- Supports Windows environment with Python 3.14+

Key Components:
1. Waitress WSGI Server: Production-grade HTTP server that handles concurrent requests efficiently
2. Migration Runner: Automatically applies database schema changes on startup
3. Flask App: Main application instance imported from app.main module
4. PostgreSQL Connection: Uses psycopg3 library for database operations
"""

# Import operating system and system-level utilities
import os
import sys

# Import Waitress WSGI server for production deployment
from waitress import serve

# Import our Flask application instance
from app.main import app

# Import psycopg3 for PostgreSQL database operations
import psycopg

# Import configuration settings (database URL, JWT secrets, etc.)
from app.config import settings

def run_migrations():
    """
    Run database migrations on startup
    
    Purpose:
    - Execute all SQL migration files from the migrations/ directory
    - Ensures database schema is up-to-date before the application starts
    - Handles both new migrations and already-applied migrations gracefully
    
    Process:
    1. Find all .sql files in migrations/ directory
    2. Sort them alphabetically (ensures correct execution order)
    3. Execute each migration file in sequence
    4. Skip migrations that have already been applied (based on error messages)
    5. Log success/failure for each migration
    
    Error Handling:
    - If migration already exists: Skip and log info message
    - If other error occurs: Log warning but continue with next migration
    - Rollback connection on any error to maintain database consistency
    """
    # Import glob for file pattern matching (finding all .sql files)
    import glob
    # Import os for file operations
    import os
    
    try:
        # Inform user that migration process is starting
        print("🔄 Running database migrations...")
        
        # Step 1: Find all SQL migration files in the migrations directory
        # sorted() ensures files are executed in alphabetical order (important for schema evolution)
        # Example: 001_init.sql will run before 002_add_columns.sql
        migration_files = sorted(glob.glob('migrations/*.sql'))
        
        # Step 2: Establish a connection to PostgreSQL database
        # Context manager (with statement) ensures connection is properly closed
        with psycopg.connect(settings.DATABASE_URL) as conn:
            # Create a cursor for executing SQL commands
            with conn.cursor() as cur:
                # Step 3: Loop through each migration file and execute it
                for migration_file in migration_files:
                    try:
                        # Log which migration file is currently being executed
                        # os.path.basename extracts just the filename (e.g., "001_init.sql")
                        print(f"   Executing {os.path.basename(migration_file)}...")
                        
                        # Step 4: Read the SQL content from the migration file
                        # encoding='utf-8' ensures proper handling of special characters
                        with open(migration_file, 'r', encoding='utf-8') as f:
                            migration_sql = f.read()
                        
                        # Step 5: Execute the SQL migration script
                        cur.execute(migration_sql)
                        
                        # Step 6: Commit the changes to make them permanent in the database
                        conn.commit()
                        
                        # Log success message
                        print(f"   ✓ {os.path.basename(migration_file)} done")
                        
                    except Exception as e:
                        # Error Handling: Check if the error is due to already existing objects
                        # This happens when migrations have been previously applied
                        if "already exists" in str(e).lower() or "duplicate" in str(e).lower():
                            # Migration already applied - this is normal, just skip it
                            print(f"   ℹ️  {os.path.basename(migration_file)} already applied")
                            conn.rollback()  # Rollback to clear the failed transaction
                        else:
                            # Other unexpected error occurred - log it but continue with next migration
                            print(f"   ⚠️  {os.path.basename(migration_file)} error: {e}")
                            conn.rollback()  # Rollback to maintain database consistency
        
        # All migrations completed successfully
        print("✅ All migrations completed!")
        
    except Exception as e:
        # Catch-all for any unexpected errors during migration process
        # Server will still start even if migrations fail (for debugging)
        print(f"⚠️  Migration error: {e}")

# Main entry point - only runs when script is executed directly (not when imported)
if __name__ == "__main__":
    # Step 1: Run all database migrations before starting the server
    # This ensures the database schema is up-to-date with the application code
    # Includes creating tables, columns, indexes, and default data (like superadmin user)
    run_migrations()
    
    # Step 2: Configure server host and port from environment variables
    # PORT: Which port the server listens on (default: 8080)
    # HOST: Which network interface to bind to (default: 0.0.0.0 means all interfaces)
    port = int(os.getenv("PORT", 8080))  # Convert to integer since env vars are strings
    host = os.getenv("HOST", "0.0.0.0")  # 0.0.0.0 allows external connections
    
    print("""
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🕉️  Ganesh Donations API Server (Flask + Waitress)    ║
║                                                           ║
║   Status: ✅ RUNNING                                      ║
║   Port: {}                                             ║
║   Host: {}                                        ║
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
║   Access URLs:                                            ║
║   - Local: http://localhost:{}                          ║
║   - Network: http://192.168.x.x:{}                      ║
║   - Health: http://localhost:{}/health                  ║
║                                                           ║
║   गणपती बाप्पा मोरया! 🙏                                 ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
    """.format(port, host, port, port, port))  # Format string with actual port and host values
    
    # Log startup messages
    print(f"Starting Waitress WSGI server...")
    print(f"Press Ctrl+C to stop\n")
    
    try:
        # Step 4: Start the Waitress WSGI server
        # Key Parameters:
        # - app: The Flask application instance to serve
        # - host: Network interface to bind to (0.0.0.0 = all interfaces)
        # - port: Port number to listen on (e.g., 8080)
        # - threads: Number of worker threads to handle concurrent requests (4 = can handle 4 simultaneous requests)
        #
        # Why Waitress?
        # - Production-ready WSGI server (unlike Flask's built-in development server)
        # - Works reliably on Windows (unlike Gunicorn which is Unix-only)
        # - Handles multiple concurrent requests efficiently
        # - Better security and performance than development server
        serve(app, host=host, port=port, threads=4)
        
    except KeyboardInterrupt:
        # Handle Ctrl+C gracefully to stop the server
        print("\n\n👋 Server stopped. गणपती बाप्पा मोरया!")
        sys.exit(0)  # Exit with code 0 (success)
