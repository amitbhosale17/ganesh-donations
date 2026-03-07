#!/usr/bin/env python3
"""
Database Reset Script
Drops all tables and recreates from simplified schema
Creates Super Admin account
"""

import os
import sys
import psycopg2
from psycopg2 import sql

# Database connection parameters
DATABASE_URL = os.getenv('DATABASE_URL')

if not DATABASE_URL:
    print("Error: DATABASE_URL environment variable not set")
    print("\nUsage:")
    print("  set DATABASE_URL=postgresql://user:password@host:port/database")
    print("  python reset_database.py")
    sys.exit(1)

def reset_database():
    """Reset database to clean state with simplified schema"""
    print("=" * 50)
    print("DATABASE RESET - SIMPLIFIED SCHEMA")
    print("=" * 50)
    print("\n⚠️  WARNING: This will DELETE ALL DATA!")
    print("⚠️  This action CANNOT be undone!\n")
    
    confirm = input("Type 'RESET' to continue: ")
    if confirm != 'RESET':
        print("\n❌ Operation cancelled")
        return
    
    try:
        # Connect to database
        print("\n📡 Connecting to database...")
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cursor = conn.cursor()
        
        # Drop all tables
        print("\n🗑️  Dropping existing tables...")
        tables = [
            'Donation',
            'OrganizationEvents',
            'EventTypes',
            'Subscriptions',
            'DonationCategory',
            'ReceiptSequence',
            '"User"',
            'Tenant'
        ]
        
        for table in tables:
            try:
                cursor.execute(f"DROP TABLE IF EXISTS {table} CASCADE")
                print(f"   ✓ Dropped {table}")
            except Exception as e:
                print(f"   ⚠️  {table} not found or error: {e}")
        
        # Drop views
        print("\n🗑️  Dropping views...")
        views = ['vw_tenant_statistics', 'vw_yearly_donations']
        for view in views:
            try:
                cursor.execute(f"DROP VIEW IF EXISTS {view} CASCADE")
                print(f"   ✓ Dropped view {view}")
            except Exception as e:
                print(f"   ⚠️  {view} not found")
        
        # Read and execute simplified schema
        print("\n📝 Creating simplified schema...")
        schema_path = os.path.join(
            os.path.dirname(__file__),
            'migrations',
            'init_simplified.sql'
        )
        
        with open(schema_path, 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        cursor.execute(schema_sql)
        print("   ✓ Schema created successfully")
        
        # Verify Super Admin created
        print("\n👤 Verifying Super Admin account...")
        cursor.execute("""
            SELECT id, name, email, phone, role 
            FROM "User" 
            WHERE role = 'SUPERADMIN'
        """)
        superadmin = cursor.fetchone()
        
        if superadmin:
            print(f"   ✓ Super Admin created successfully")
            print(f"     ID: {superadmin[0]}")
            print(f"     Name: {superadmin[1]}")
            print(f"     Email: {superadmin[2]}")
            print(f"     Phone: {superadmin[3]}")
        else:
            print("   ❌ Failed to create Super Admin")
        
        # Show table count
        print("\n📊 Database Statistics:")
        cursor.execute("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_type = 'BASE TABLE'
            ORDER BY table_name
        """)
        tables = cursor.fetchall()
        print(f"   Total tables: {len(tables)}")
        for table in tables:
            print(f"     - {table[0]}")
        
        cursor.close()
        conn.close()
        
        print("\n" + "=" * 50)
        print("✅ DATABASE RESET COMPLETE!")
        print("=" * 50)
        print("\n🔑 Super Admin Login Credentials:")
        print("   Email:    superadmin@donation.local")
        print("   Password: SuperAdmin@123")
        print("   Phone:    9999999999")
        print("\n📱 You can now start the application and login")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ Error resetting database: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    reset_database()
