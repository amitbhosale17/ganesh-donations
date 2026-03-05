"""
Auto-migration script for ReceiptSequence table
Runs automatically on server startup
"""
import os
import psycopg
from psycopg.rows import dict_row

def run_migration():
    """Add ReceiptSequence table if it doesn't exist"""
    try:
        # Get database URL from environment
        database_url = os.environ.get('DATABASE_URL')
        
        if not database_url:
            print("⚠️  DATABASE_URL not found, skipping migration")
            return
        
        print("🔄 Running auto-migration for ReceiptSequence table...")
        
        # Connect to database
        with psycopg.connect(database_url) as conn:
            with conn.cursor(row_factory=dict_row) as cursor:
                
                # Check if table exists
                cursor.execute("""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_name = 'receiptsequence'
                    );
                """)
                
                result = cursor.fetchone()
                table_exists = result['exists']
                
                if table_exists:
                    print("✅ ReceiptSequence table already exists, skipping migration")
                    return
                
                print("📝 Creating ReceiptSequence table...")
                
                # Create table
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS ReceiptSequence (
                        tenant_id INTEGER PRIMARY KEY REFERENCES Tenant(id),
                        last_no INTEGER NOT NULL DEFAULT 0,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                
                print("📝 Initializing sequences for existing tenants...")
                
                # Initialize for existing tenants
                cursor.execute("""
                    INSERT INTO ReceiptSequence (tenant_id, last_no)
                    SELECT DISTINCT t.id, COALESCE(
                        (SELECT COUNT(*) FROM Donation d WHERE d.tenant_id = t.id), 
                        0
                    )
                    FROM Tenant t
                    WHERE NOT EXISTS (
                        SELECT 1 FROM ReceiptSequence rs WHERE rs.tenant_id = t.id
                    )
                    ON CONFLICT (tenant_id) DO NOTHING;
                """)
                
                # Verify
                cursor.execute("SELECT COUNT(*) as count FROM ReceiptSequence")
                count = cursor.fetchone()['count']
                
                print(f"✅ Migration completed! {count} tenant sequences initialized")
                
                conn.commit()
        
    except Exception as e:
        print(f"❌ Migration error: {e}")
        print("⚠️  Server will continue, but receipt numbers may not work")

if __name__ == '__main__':
    run_migration()
