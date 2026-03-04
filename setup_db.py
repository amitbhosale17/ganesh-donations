"""Setup database and run migrations"""
import os
import psycopg
from dotenv import load_dotenv

load_dotenv()

# Get database URL
db_url = os.getenv('DATABASE_URL')
print(f"Using database: {db_url}")

# Parse connection details
parts = db_url.replace('postgresql://', '').split('@')
user_pass = parts[0].split(':')
host_db = parts[1].split('/')
username = user_pass[0]
password = user_pass[1]
host_port = host_db[0].split(':')
host = host_port[0]
port = host_port[1] if len(host_port) > 1 else '5432'
dbname = host_db[1]

# First, connect to postgres database to create our database
print("\n1. Creating database...")
try:
    conn = psycopg.connect(
        f"postgresql://{username}:{password}@{host}:{port}/postgres",
        autocommit=True
    )
    cur = conn.cursor()
    cur.execute(f"SELECT 1 FROM pg_database WHERE datname = '{dbname}'")
    if not cur.fetchone():
        cur.execute(f'CREATE DATABASE {dbname}')
        print(f"✅ Database '{dbname}' created!")
    else:
        print(f"✅ Database '{dbname}' already exists")
    cur.close()
    conn.close()
except Exception as e:
    print(f"❌ Error creating database: {e}")
    exit(1)

# Now connect to our database and run migrations
print("\n2. Running migrations...")
try:
    conn = psycopg.connect(db_url)
    cur = conn.cursor()
    
    # Read and execute migration
    with open('migrations/001_init.sql', 'r', encoding='utf-8') as f:
        migration_sql = f.read()
    
    cur.execute(migration_sql)
    conn.commit()
    print("✅ Migrations completed!")
    
    # Verify tables
    cur.execute("""
        SELECT table_name FROM information_schema.tables 
        WHERE table_schema = 'public'
        ORDER BY table_name
    """)
    tables = cur.fetchall()
    print("\n3. Tables created:")
    for table in tables:
        print(f"   - {table[0]}")
    
    cur.close()
    conn.close()
    
    print("\n✅ Database setup complete!")
    print("\nYou can now restart your server.")
    
except Exception as e:
    print(f"❌ Error running migrations: {e}")
    exit(1)
