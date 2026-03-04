import psycopg2
from app.config import settings

def run_migration_003():
    """Run the 003_add_superadmin migration"""
    
    conn = psycopg2.connect(settings.DATABASE_URL)
    cursor = conn.cursor()
    
    try:
        # Read migration file
        with open('migrations/003_add_superadmin.sql', 'r', encoding='utf-8') as f:
            sql = f.read()
        
        # Execute migration
        cursor.execute(sql)
        conn.commit()
        
        print("✅ Migration 003_add_superadmin completed successfully!")
        print()
        print("=" * 60)
        print("🔧 SuperAdmin Credentials Created")
        print("=" * 60)
        print("Email: superadmin@system.local")
        print("Password: Super@123")
        print()
        print("Use these credentials to login and manage all mandals!")
        print("=" * 60)
        
    except Exception as e:
        conn.rollback()
        print(f"❌ Migration failed: {e}")
        raise
    finally:
        cursor.close()
        conn.close()

if __name__ == "__main__":
    run_migration_003()
