"""
Database Connection Management Module

Purpose:
- Manages PostgreSQL database connections using connection pooling
- Provides context managers for safe database operations
- Ensures proper resource cleanup and transaction management

Key Concepts:

1. Connection Pooling:
   - Instead of creating a new database connection for each request (slow and resource-intensive)
   - We maintain a pool of reusable connections
   - Connections are borrowed from the pool, used, and returned
   - This dramatically improves performance and scalability

2. Context Managers (with statements):
   - Ensures connections/cursors are properly closed even if errors occur
   - Automatically handles commit/rollback based on success/failure
   - Prevents resource leaks (unclosed connections)

3. psycopg3 Library:
   - Modern PostgreSQL adapter for Python
   - Supports connection pooling out of the box
   - dict_row factory returns results as dictionaries instead of tuples
   - Better performance and cleaner API than psycopg2

Usage Examples:
    # Execute a query and commit
    with get_db_cursor(commit=True) as cur:
        cur.execute(\"INSERT INTO users (name) VALUES (%s)\", (\"John\",))
    
    # Execute multiple operations in a transaction
    with get_transaction() as cur:
        cur.execute(\"UPDATE accounts SET balance = balance - 100 WHERE id = 1\")
        cur.execute(\"UPDATE accounts SET balance = balance + 100 WHERE id = 2\")
        # Both succeed or both fail together
\"\"\"

# Import psycopg3 - modern PostgreSQL database adapter for Python
import psycopg
# Import dict_row to get query results as dictionaries
from psycopg.rows import dict_row
# Import ConnectionPool for efficient connection reuse
from psycopg_pool import ConnectionPool
# Import contextmanager decorator for creating context managers
from contextlib import contextmanager
# Import application configuration settings
from app.config import settings
# Import logging for error reporting
import logging

# Create logger instance for this module
logger = logging.getLogger(__name__)

# Global variable to hold the connection pool
# Initialized to None, set by init_db_pool() during app startup
pool = None


def init_db_pool():
    """
    Initialize database connection pool
    
    Purpose:
    - Creates a pool of reusable PostgreSQL connections
    - Called once during application startup (in app/main.py)
    - Must be called before any database operations
    
    Connection Pool Benefits:
    - Faster: Reuses existing connections instead of creating new ones
    - Scalable: Limits maximum connections to prevent overwhelming the database
    - Efficient: Automatically manages connection lifecycle
    
    Parameters:
    - conninfo: PostgreSQL connection string (from settings.DATABASE_URL)
    - min_size: Minimum connections to maintain (1 = always keep at least 1 open)
    - max_size: Maximum connections allowed (20 = can handle 20 concurrent requests)
    
    Raises:
    - Exception if database connection fails (wrong URL, database down, etc.)
    """
    # Use global keyword to modify the module-level pool variable
    global pool
    
    try:
        # Create the connection pool with specified parameters
        # conninfo: Database connection string (contains host, port, username, password, database name)
        # min_size: Keep at least 1 connection alive at all times (reduces latency for first request)
        # max_size: Allow up to 20 concurrent connections (handles high load)
        pool = ConnectionPool(
            conninfo=settings.DATABASE_URL,
            min_size=1,
            max_size=20
        )
        
        # Log successful initialization
        logger.info("✅ Database pool initialized")
        
    except Exception as e:
        # Log error and re-raise exception (let calling code handle it)
        logger.error(f"❌ Database pool initialization failed: {e}")
        raise


@contextmanager
def get_db_connection():
    """
    Get database connection from pool
    
    Purpose:
    - Borrows a connection from the pool
    - Ensures connection is returned to pool after use
    - Use when you need just the connection object (rare - usually use get_db_cursor instead)
    
    Usage:
        with get_db_connection() as conn:
            # Use connection here
            # Connection automatically returned to pool when exiting the block
    
    How Context Manager Works:
    1. pool.connection() borrows a connection from the pool
    2. 'yield conn' provides the connection to your code
    3. After your code completes (or errors), connection is auto-returned to pool
    """
    # Context manager from the pool - automatically handles acquire/release
    with pool.connection() as conn:
        # Yield the connection to the calling code
        # Execution pauses here until the calling code finishes
        yield conn
        # After calling code finishes, connection is automatically returned to pool


@contextmanager
def get_db_cursor(commit=False):
    """
    Get database cursor with auto-commit option
    
    Purpose:
    - Most commonly used function for database operations
    - Provides a cursor for executing SQL queries
    - Returns results as dictionaries (easier to work with than tuples)
    - Optionally commits changes automatically
    
    Parameters:
    - commit (bool): If True, automatically commit changes on success
                     If False, no commit (use for read-only queries)
    
    Usage Examples:
        # Read-only query (no commit needed)
        with get_db_cursor() as cur:
            cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
            user = cur.fetchone()
        
        # Write query (commit=True)
        with get_db_cursor(commit=True) as cur:
            cur.execute("INSERT INTO users (name) VALUES (%s)", ("John",))
    
    Error Handling:
    - If an exception occurs, automatically rolls back the transaction
    - Ensures database remains consistent even when errors happen
    - Connection and cursor are properly closed
    
    Dictionary Results:
    - row_factory=dict_row makes results accessible as dicts
    - Example: user["name"] instead of user[0]
    """
    # Get a connection from the pool
    with pool.connection() as conn:
        # Create a cursor with dict_row factory (returns results as dictionaries)
        # row_factory=dict_row: Results are dicts like {"id": 1, "name": "John"}
        # Without dict_row: Results would be tuples like (1, "John")
        with conn.cursor(row_factory=dict_row) as cursor:
            try:
                # Yield cursor to calling code
                yield cursor
                
                # If commit=True and no errors occurred, commit the transaction
                # Commit makes changes permanent in the database
                if commit:
                    conn.commit()
                    
            except Exception as e:
                # If any error occurs, rollback to undo any changes
                # This ensures database consistency (all-or-nothing)
                conn.rollback()
                
                # Re-raise the exception so calling code knows something went wrong
                raise e


@contextmanager
def get_transaction():
    """
    Get database transaction context
    
    Purpose:
    - Use when you need to execute multiple related operations atomically
    - Automatically commits if all operations succeed
    - Automatically rolls back if any operation fails
    - Ensures data consistency for multi-step operations
    
    Transaction Guarantees (ACID):
    - Atomicity: All operations succeed together or all fail together
    - Consistency: Database remains in valid state
    - Isolation: Other transactions do not see partial results
    - Durability: Committed changes are permanent
    
    Usage Example:
        # Transfer money between accounts (must be atomic)
        with get_transaction() as cur:
            # Deduct from account 1
            cur.execute("UPDATE accounts SET balance = balance - %s WHERE id = %s", (100, 1))
            
            # Add to account 2
            cur.execute("UPDATE accounts SET balance = balance + %s WHERE id = %s", (100, 2))
            
            # Both operations committed together
            # If either fails, both are rolled back (money not lost or duplicated)
    
    Difference from get_db_cursor(commit=True):
    - get_transaction: ALWAYS commits at end (use for write operations)
    - get_db_cursor(commit=True): Commits at end (same behavior)
    - get_transaction is more explicit about intent
    """
    # Get connection from pool
    with pool.connection() as conn:
        # Create cursor with dictionary row factory
        with conn.cursor(row_factory=dict_row) as cursor:
            try:
                # Yield cursor to calling code for executing queries
                yield cursor
                
                # If no exceptions occurred, commit all changes
                # This makes all operations in the transaction permanent
                conn.commit()
                
            except Exception as e:
                # If any exception occurs, rollback all changes
                # This undoes ALL operations in the transaction (atomicity)
                conn.rollback()
                
                # Re-raise exception for error handling by calling code
                raise e


def close_db_pool():
    """
    Close database connection pool
    
    Purpose:
    - Cleanly shuts down all database connections
    - Called during application shutdown (via atexit.register in main.py)
    - Ensures no connections are left hanging
    
    Why This Matters:
    - Prevents connection leaks (exhausting database connection limits)
    - Allows database to clean up resources
    - Important for graceful shutdown in production
    
    When Called:
    - Automatically called when app exits (registered with atexit in main.py)
    - Can be called manually during tests or shutdown procedures
    """
    # Access the global pool variable
    global pool
    
    # Check if pool exists (might be None if init_db_pool was never called)
    if pool:
        # Close all connections in the pool
        # This disconnects from PostgreSQL and frees resources
        pool.close()
        
        # Log the shutdown for monitoring/debugging
        logger.info("Database pool closed")
