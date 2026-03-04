import psycopg
from app.config import settings
import sys

def run_migration(migration_file):
    """Run a database migration"""
    
    try:
        # Read migration file
        with open(migration_file, 'r', encoding='utf-8') as f:
            sql = f.read()
        
        # Execute migration using psycopg 3
        with psycopg.connect(settings.DATABASE_URL) as conn:
            with conn.cursor() as cursor:
                cursor.execute(sql)
                conn.commit()
        
        print(f"✅ Migration {migration_file} completed successfully!")
        
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        raise

if __name__ == "__main__":
    if len(sys.argv) > 1:
        run_migration(sys.argv[1])
    else:
        # Default to 002_add_donor_fields.sql
        run_migration('migrations/002_add_donor_fields.sql')
