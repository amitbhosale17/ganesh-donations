"""Create admin user with proper password hashing"""
import os
import psycopg
from dotenv import load_dotenv
import bcrypt

load_dotenv()

db_url = os.getenv('DATABASE_URL')
print(f"Connecting to database...")

try:
    conn = psycopg.connect(db_url)
    cur = conn.cursor()
    
    # Check if admin user exists
    cur.execute("SELECT id, email, password_hash FROM \"User\" WHERE email = 'admin@ganesh.local'")
    admin = cur.fetchone()
    
    if admin:
        print(f"\n✅ Admin user exists: {admin[1]}")
        print(f"Current password_hash: {admin[2]}")
        
        # Hash the password properly
        password = 'Admin@123'
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Update with proper hash
        cur.execute(
            "UPDATE \"User\" SET password_hash = %s WHERE email = 'admin@ganesh.local'",
            (password_hash,)
        )
        conn.commit()
        print(f"\n✅ Updated admin password to: Admin@123")
        print(f"New hash: {password_hash}")
    else:
        print("\n❌ No admin user found. Creating one...")
        
        # Get tenant ID
        cur.execute("SELECT id FROM Tenant LIMIT 1")
        tenant = cur.fetchone()
        
        if not tenant:
            print("❌ No tenant found. Creating default tenant...")
            cur.execute("""
                INSERT INTO Tenant (name, receipt_prefix, address, contact_phone) 
                VALUES ('Shree Ganesh Mandal', 'GANESH', 'Mumbai, Maharashtra', '9876543210')
                RETURNING id
            """)
            tenant_id = cur.fetchone()[0]
        else:
            tenant_id = tenant[0]
        
        # Hash password
        password = 'Admin@123'
        password_hash = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # Create admin user
        cur.execute("""
            INSERT INTO "User" (tenant_id, name, email, role, password_hash, status) 
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (tenant_id, 'Admin User', 'admin@ganesh.local', 'ADMIN', password_hash, 'ACTIVE'))
        
        conn.commit()
        print(f"\n✅ Created admin user")
        print(f"Email: admin@ganesh.local")
        print(f"Password: Admin@123")
    
    # Show all users
    print("\n📋 All users in database:")
    cur.execute('SELECT id, name, email, phone, role, status FROM "User"')
    users = cur.fetchall()
    for user in users:
        print(f"  - ID: {user[0]}, Name: {user[1]}, Email: {user[2]}, Phone: {user[3]}, Role: {user[4]}, Status: {user[5]}")
    
    cur.close()
    conn.close()
    
    print("\n" + "="*60)
    print("✅ Setup Complete!")
    print("="*60)
    print("\nLogin Credentials:")
    print("  Email: admin@ganesh.local")
    print("  Password: Admin@123")
    print("\n" + "="*60)

except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
