"""
Add SuperAdmin user to the database with properly hashed password
Run this once to create the superadmin account
"""
import os
import psycopg
from passlib.hash import bcrypt

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://ganesh_admin:NyJZcl0eqUZSrhsxYqTvA8ohLYObtBfe@dpg-d6j9qb15pdvs738fvs0g-a.oregon-postgres.render.com:5432/ganesh_donations")

# Hash the password
password = "Super@123"
password_hash = bcrypt.hash(password)

print("🔐 Hashing password...")
print(f"Password: {password}")
print(f"Hash: {password_hash}")

try:
    with psycopg.connect(DATABASE_URL) as conn:
        with conn.cursor() as cur:
            # Create system tenant if not exists
            print("\n📦 Creating system tenant...")
            cur.execute("""
                INSERT INTO Tenant (id, name, address, receipt_prefix) 
                VALUES (0, 'System Admin', 'System', 'SYS')
                ON CONFLICT (id) DO NOTHING
            """)
            
            # Check if superadmin exists
            cur.execute("SELECT id FROM \"User\" WHERE email = 'superadmin@system.local'")
            existing = cur.fetchone()
            
            if existing:
                # Update existing user
                print("\n🔄 Updating existing superadmin user...")
                cur.execute("""
                    UPDATE "User" 
                    SET password_hash = %s, role = 'SUPERADMIN', status = 'ACTIVE'
                    WHERE email = 'superadmin@system.local'
                """, (password_hash,))
                print("✅ SuperAdmin user updated!")
            else:
                # Create new user
                print("\n👤 Creating superadmin user...")
                cur.execute("""
                    INSERT INTO "User" (tenant_id, name, email, role, password_hash, status)
                    VALUES (0, 'Super Admin', 'superadmin@system.local', 'SUPERADMIN', %s, 'ACTIVE')
                """, (password_hash,))
                print("✅ SuperAdmin user created!")
            
            conn.commit()
            
            # Verify
            cur.execute("SELECT id, name, email, role FROM \"User\" WHERE email = 'superadmin@system.local'")
            user = cur.fetchone()
            print(f"\n✨ SuperAdmin details:")
            print(f"   ID: {user[0]}")
            print(f"   Name: {user[1]}")
            print(f"   Email: {user[2]}")
            print(f"   Role: {user[3]}")
            print(f"\n🔑 Login credentials:")
            print(f"   Email: superadmin@system.local")
            print(f"   Password: Super@123")
            
except Exception as e:
    print(f"❌ Error: {e}")
