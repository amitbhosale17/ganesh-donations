"""Update user passwords to plain text"""
from app.database import init_db_pool, get_db_cursor

# Initialize database pool
init_db_pool()

with get_db_cursor() as cursor:
    # Update admin password
    cursor.execute(
        'UPDATE "User" SET password_hash = %s WHERE email = %s',
        ('admin123', 'admin@ganesh.local')
    )
    
    # Update collector password
    cursor.execute(
        'UPDATE "User" SET password_hash = %s WHERE phone = %s',
        ('collector123', '9876543221')
    )
    
    cursor.connection.commit()
    print("✅ Passwords updated to plain text:")
    print("  - Admin: admin@ganesh.local / Admin@123")
    print("  - Collector: 9876543221 / Collector@123")
