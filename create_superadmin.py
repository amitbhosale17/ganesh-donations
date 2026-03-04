"""
Create default SuperAdmin user
Run this once after deployment
"""
import psycopg
from app.config import settings
from passlib.hash import bcrypt

# Default SuperAdmin credentials
DEFAULT_SUPERADMIN = {
    'phone': '9999999999',
    'email': 'superadmin@ganesh.com',
    'password': 'Admin@123',  # Change this after first login!
    'name': 'Super Admin',
    'role': 'SUPERADMIN',
    'status': 'ACTIVE'
}

try:
    print("🔐 Creating default SuperAdmin user...")
    
    # Hash password
    hashed_password = bcrypt.hash(DEFAULT_SUPERADMIN['password'])
    
    # Connect and insert
    with psycopg.connect(settings.DATABASE_URL) as conn:
        with conn.cursor() as cur:
            # Check if superadmin already exists
            cur.execute("SELECT id FROM users WHERE role = 'SUPERADMIN' LIMIT 1")
            existing = cur.fetchone()
            
            if existing:
                print("ℹ️  SuperAdmin user already exists")
            else:
                cur.execute("""
                    INSERT INTO users (phone, email, password_hash, name, role, status, tenant_id)
                    VALUES (%s, %s, %s, %s, %s, %s, NULL)
                """, (
                    DEFAULT_SUPERADMIN['phone'],
                    DEFAULT_SUPERADMIN['email'],
                    hashed_password,
                    DEFAULT_SUPERADMIN['name'],
                    DEFAULT_SUPERADMIN['role'],
                    DEFAULT_SUPERADMIN['status']
                ))
                conn.commit()
                print("✅ SuperAdmin user created successfully!")
                print(f"\n📱 Login credentials:")
                print(f"   Phone: {DEFAULT_SUPERADMIN['phone']}")
                print(f"   Password: {DEFAULT_SUPERADMIN['password']}")
                print(f"\n⚠️  Please change the password after first login!\n")
                
except Exception as e:
    print(f"❌ Error: {e}")
    raise
