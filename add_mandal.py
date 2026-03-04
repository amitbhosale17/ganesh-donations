"""
Helper script to create a new tenant (mandal) in the system
Usage: python add_mandal.py
"""

import psycopg2
from app.config import settings

def add_new_mandal():
    print("=" * 60)
    print("🕉️  Add New Mandal to Ganesh Donations App")
    print("=" * 60)
    print()
    
    # Collect mandal details
    print("Enter Mandal Details:")
    print("-" * 60)
    name = input("Mandal Name (e.g., श्री गणेश मंडळ): ").strip()
    address = input("Address (e.g., पुणे, महाराष्ट्र): ").strip()
    phone = input("Contact Phone (e.g., 9876543210): ").strip()
    prefix = input("Receipt Prefix (e.g., GAN): ").strip().upper()
    
    print()
    print("Enter Admin Details:")
    print("-" * 60)
    admin_name = input("Admin Name (default: Admin): ").strip() or "Admin"
    admin_phone = input("Admin Phone (for login): ").strip()
    admin_password = input("Temp Password (default: Admin@123): ").strip() or "Admin@123"
    
    print()
    print("Optional Officials:")
    print("-" * 60)
    president = input("President Name (optional): ").strip() or None
    vice_president = input("Vice President (optional): ").strip() or None
    secretary = input("Secretary (optional): ").strip() or None
    treasurer = input("Treasurer (optional): ").strip() or None
    reg_no = input("Registration Number (optional): ").strip() or None
    
    # Confirm
    print()
    print("=" * 60)
    print("CONFIRM NEW MANDAL")
    print("=" * 60)
    print(f"Mandal: {name}")
    print(f"Address: {address}")
    print(f"Phone: {phone}")
    print(f"Prefix: {prefix}")
    print(f"Admin: {admin_name} ({admin_phone})")
    print(f"Password: {admin_password}")
    if president:
        print(f"President: {president}")
    print()
    
    confirm = input("Create this mandal? (yes/no): ").strip().lower()
    if confirm != 'yes':
        print("❌ Cancelled")
        return
    
    # Create in database
    try:
        conn = psycopg2.connect(settings.DATABASE_URL)
        cursor = conn.cursor()
        
        # Create tenant
        cursor.execute("""
            INSERT INTO Tenant (
                name, address, contact_phone, receipt_prefix,
                president_name, vice_president_name, secretary_name, 
                treasurer_name, registration_no
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            name, address, phone, prefix,
            president, vice_president, secretary, treasurer, reg_no
        ))
        
        tenant_id = cursor.fetchone()[0]
        print(f"✅ Tenant created with ID: {tenant_id}")
        
        # Create admin user
        cursor.execute("""
            INSERT INTO "User" (
                tenant_id, name, phone, role, password_hash, status
            ) VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (
            tenant_id, admin_name, admin_phone, 'ADMIN', admin_password, 'ACTIVE'
        ))
        
        user_id = cursor.fetchone()[0]
        print(f"✅ Admin user created with ID: {user_id}")
        
        # Create receipt sequence
        cursor.execute("""
            INSERT INTO ReceiptSequence (tenant_id, last_no)
            VALUES (%s, 0)
        """, (tenant_id,))
        
        print(f"✅ Receipt sequence initialized")
        
        conn.commit()
        
        print()
        print("=" * 60)
        print("🎉 SUCCESS! Mandal Created Successfully")
        print("=" * 60)
        print()
        print("📋 CREDENTIALS TO SEND TO CUSTOMER:")
        print("-" * 60)
        print(f"App URL: http://localhost:8080 (or your hosted URL)")
        print(f"Login Phone: {admin_phone}")
        print(f"Password: {admin_password}")
        print()
        print("📝 NEXT STEPS:")
        print("-" * 60)
        print("1. Send credentials to customer")
        print("2. Guide them to upload logo and QR code")
        print("3. Help them create collector accounts")
        print("4. Test donation flow")
        print("5. Collect payment! 💰")
        print()
        
        cursor.close()
        conn.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")
        if conn:
            conn.rollback()

if __name__ == "__main__":
    add_new_mandal()
