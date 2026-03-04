from flask import Blueprint, request, jsonify
from app.middleware.auth import require_admin
from app.database import get_db_cursor
import secrets
import string

users_bp = Blueprint('users', __name__)

def generate_random_password(length=8):
    """Generate a random password"""
    characters = string.ascii_letters + string.digits
    return ''.join(secrets.choice(characters) for _ in range(length))

@users_bp.route('/users', methods=['GET'])
@require_admin
def list_users(user):
    """List all users in the tenant (admin only)"""
    try:
        tenant_id = user['tenant_id']
        
        # Get search query
        search = request.args.get('search', '').strip()
        
        with get_db_cursor() as cursor:
            # Build query
            query = """
                SELECT id, name, email, phone, role, status, created_at
                FROM "User"
                WHERE tenant_id = %s AND role != 'SUPERADMIN'
            """
            params = [tenant_id]
            
            # Add search filter
            if search:
                query += " AND (name ILIKE %s OR email ILIKE %s OR phone ILIKE %s)"
                search_param = f"%{search}%"
                params.extend([search_param, search_param, search_param])
            
            query += " ORDER BY created_at DESC"
            
            cursor.execute(query, params)
            users = cursor.fetchall()
            
            # Convert datetime to ISO format and status to is_active
            for user in users:
                if user.get('created_at'):
                    user['created_at'] = user['created_at'].isoformat()
                # Convert status to is_active for frontend compatibility
                user['is_active'] = user.get('status') == 'ACTIVE'
                user.pop('status', None)
            
            return jsonify(users)
        
    except Exception as e:
        print(f"Error listing users: {e}")
        return jsonify({"error": str(e)}), 500

@users_bp.route('/users', methods=['POST'])
@require_admin
def create_user(user):
    """Create a new user (collector)"""
    try:
        tenant_id = user['tenant_id']
        
        data = request.get_json()
        
        # Validate required fields
        name = data.get('name', '').strip()
        email = data.get('email', '').strip()
        phone = data.get('phone', '').strip()
        role = data.get('role', 'COLLECTOR').upper()
        
        if not name or not email:
            return jsonify({"error": "Name and email are required"}), 400
        
        # Only allow creating COLLECTOR or ADMIN roles
        if role not in ['COLLECTOR', 'ADMIN']:
            return jsonify({"error": "Invalid role"}), 400
        
        # Generate random password if not provided
        password = data.get('password', '').strip()
        if not password:
            password = generate_random_password()
        
        with get_db_cursor(commit=True) as cursor:
            # Check if email already exists in this tenant
            cursor.execute(
                "SELECT id FROM \"User\" WHERE tenant_id = %s AND email = %s",
                (tenant_id, email)
            )
            if cursor.fetchone():
                return jsonify({"error": "Email already exists"}), 400
            
            # Insert new user
            cursor.execute("""
                INSERT INTO "User" (tenant_id, name, email, phone, password_hash, role, status)
                VALUES (%s, %s, %s, %s, %s, %s, 'ACTIVE')
                RETURNING id, name, email, phone, role, status, created_at
            """, (tenant_id, name, email, phone, password, role))
            
            user = cursor.fetchone()
            
            # Include generated password in response
            user['generated_password'] = password
            user['created_at'] = user['created_at'].isoformat()
            # Convert status to is_active for frontend
            user['is_active'] = user.get('status') == 'ACTIVE'
            user.pop('status', None)
            
            return jsonify(user), 201
        
    except Exception as e:
        print(f"Error creating user: {e}")
        return jsonify({"error": str(e)}), 500

@users_bp.route('/users/<int:user_id>', methods=['PUT'])
@require_admin
def update_user(user, user_id):
    """Update user details"""
    try:
        tenant_id = user['tenant_id']
        
        data = request.get_json()
        
        # Prevent user from disabling themselves
        if user_id == user['id'] and 'is_active' in data and not data['is_active']:
            return jsonify({"error": "You cannot disable your own account"}), 400
        
        with get_db_cursor(commit=True) as cursor:
            # Check if user exists and belongs to tenant
            cursor.execute(
                "SELECT id, role FROM \"User\" WHERE id = %s AND tenant_id = %s",
                (user_id, tenant_id)
            )
            existing_user = cursor.fetchone()
            if not existing_user:
                return jsonify({"error": "User not found"}), 404
            
            # Don't allow updating SUPERADMIN
            if existing_user['role'] == 'SUPERADMIN':
                return jsonify({"error": "Cannot update superadmin"}), 403
            
            # Build update query
            updates = []
            params = []
            
            if 'name' in data:
                updates.append("name = %s")
                params.append(data['name'].strip())
            
            if 'email' in data:
                updates.append("email = %s")
                params.append(data['email'].strip())
            
            if 'phone' in data:
                updates.append("phone = %s")
                params.append(data['phone'].strip())
            
            if 'role' in data and data['role'].upper() in ['COLLECTOR', 'ADMIN']:
                updates.append("role = %s")
                params.append(data['role'].upper())
            
            if 'is_active' in data:
                updates.append("status = %s")
                params.append('ACTIVE' if bool(data['is_active']) else 'DISABLED')
            
            if not updates:
                return jsonify({"error": "No fields to update"}), 400
            
            # Add WHERE clause params
            params.extend([user_id, tenant_id])
            
            # Execute update
            query = f"""
                UPDATE "User"
                SET {', '.join(updates)}
                WHERE id = %s AND tenant_id = %s
                RETURNING id, name, email, phone, role, status, created_at
            """
            
            cursor.execute(query, params)
            user = cursor.fetchone()
            user['created_at'] = user['created_at'].isoformat()
            # Convert status to is_active for frontend
            user['is_active'] = user.get('status') == 'ACTIVE'
            user.pop('status', None)
            
            return jsonify(user)
        
    except Exception as e:
        print(f"Error updating user: {e}")
        return jsonify({"error": str(e)}), 500

@users_bp.route('/users/<int:user_id>/reset-password', methods=['POST'])
@require_admin
def reset_password(user, user_id):
    """Reset user password"""
    try:
        tenant_id = user['tenant_id']
        
        data = request.get_json() or {}
        
        # Generate new password
        new_password = data.get('password', '').strip()
        if not new_password:
            new_password = generate_random_password()
        
        with get_db_cursor(commit=True) as cursor:
            # Check if user exists and belongs to tenant
            cursor.execute(
                "SELECT id, role FROM \"User\" WHERE id = %s AND tenant_id = %s",
                (user_id, tenant_id)
            )
            existing_user = cursor.fetchone()
            if not existing_user:
                return jsonify({"error": "User not found"}), 404
            
            # Don't allow resetting SUPERADMIN password
            if existing_user['role'] == 'SUPERADMIN':
                return jsonify({"error": "Cannot reset superadmin password"}), 403
            
            # Update password
            cursor.execute(
                "UPDATE \"User\" SET password_hash = %s WHERE id = %s AND tenant_id = %s",
                (new_password, user_id, tenant_id)
            )
            
            return jsonify({
                "message": "Password reset successfully",
                "new_password": new_password
            })
        
    except Exception as e:
        print(f"Error resetting password: {e}")
        return jsonify({"error": str(e)}), 500

@users_bp.route('/users/<int:user_id>', methods=['DELETE'])
@require_admin
def delete_user(user, user_id):
    """Disable user (soft delete)"""
    try:
        tenant_id = user['tenant_id']
        
        # Prevent user from deleting themselves
        if user_id == user['id']:
            return jsonify({"error": "You cannot delete your own account"}), 400
        
        with get_db_cursor(commit=True) as cursor:
            # Check if user exists and belongs to tenant
            cursor.execute(
                "SELECT id, role FROM \"User\" WHERE id = %s AND tenant_id = %s",
                (user_id, tenant_id)
            )
            existing_user = cursor.fetchone()
            if not existing_user:
                return jsonify({"error": "User not found"}), 404
            
            # Don't allow deleting SUPERADMIN
            if existing_user['role'] == 'SUPERADMIN':
                return jsonify({"error": "Cannot delete superadmin"}), 403
            
            # Soft delete - set status to DISABLED
            cursor.execute(
                "UPDATE \"User\" SET status = 'DISABLED' WHERE id = %s AND tenant_id = %s",
                (user_id, tenant_id)
            )
            
            return jsonify({"message": "User disabled successfully"})
        
    except Exception as e:
        print(f"Error deleting user: {e}")
        return jsonify({"error": str(e)}), 500
