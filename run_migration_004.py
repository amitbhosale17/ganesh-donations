"""
Auto-run Migration 004: Subscriptions and Multi-Event Support
Runs automatically on server startup
"""
import psycopg
import os
from pathlib import Path

def run_migration_004():
    """Run migration 004 automatically"""
    try:
        # Get database URL from environment
        database_url = os.getenv('DATABASE_URL')
        if not database_url:
            print("⚠️  DATABASE_URL not set, skipping migration")
            return
        
        print("=" * 60)
        print("🔄 Running Migration 004: Subscriptions & Multi-Event Support")
        print("=" * 60)
        
        # Connect to database
        with psycopg.connect(database_url) as conn:
            with conn.cursor() as cursor:
                # Read migration SQL
                migration_file = Path(__file__).parent / 'migrations' / 'migration_004_subscriptions_and_events.sql'
                
                if not migration_file.exists():
                    print(f"⚠️  Migration file not found: {migration_file}")
                    return
                
                with open(migration_file, 'r', encoding='utf-8') as f:
                    migration_sql = f.read()
                
                # Execute migration
                print("📝 Executing migration SQL...")
                cursor.execute(migration_sql)
                conn.commit()
                
                print("✅ Migration 004 completed successfully!")
                print("   - Created Subscriptions table")
                print("   - Created EventTypes table (with default events)")
                print("   - Created OrganizationEvents table")
                print("   - Added donation_year to Donations")
                print("   - Added event_id to Donations")
                print("   - Created indexes for better performance")
                print("=" * 60)
    
    except Exception as e:
        print(f"❌ Error running migration 004: {e}")
        print(f"   Type: {type(e).__name__}")
        import traceback
        traceback.print_exc()

if __name__ == '__main__':
    run_migration_004()
