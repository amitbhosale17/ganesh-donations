from flask import Blueprint, request, jsonify
from app.database import get_db_cursor
from app.middleware.auth import require_superadmin

bp = Blueprint('superadmin', __name__, url_prefix='/superadmin')


@bp.route("/tenants", methods=["GET"])
@require_superadmin
def get_all_tenants(user):
    """Get all tenants (mandals) in the system"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT
                    t.*,
                    (SELECT COUNT(*) FROM "User" u WHERE u.tenant_id = t.id) AS user_count,
                    (SELECT COUNT(*) FROM Donation d WHERE d.tenant_id = t.id
                        AND d.payment_status != 'CANCELLED') AS donation_count,
                    COALESCE(
                        (SELECT SUM(d.amount) FROM Donation d
                         WHERE d.tenant_id = t.id
                           AND d.payment_status != 'CANCELLED'), 0
                    ) AS total_amount
                FROM Tenant t
                WHERE t.id > 0
                ORDER BY t.created_at DESC
            """)
            
            tenants = cursor.fetchall()
            return jsonify([dict(t) for t in tenants])
    
    except Exception as e:
        print(f"Error getting all tenants: {e}")
        return jsonify([])


@bp.route("/tenants", methods=["POST"])
@require_superadmin
def create_tenant(user):
    """Create a new tenant (mandal)"""
    
    data = request.get_json()
    
    # Validate required fields
    required = ['name', 'address', 'receipt_prefix']
    for field in required:
        if not data.get(field):
            return jsonify({"detail": f"Missing required field: {field}"}), 400
    
    with get_db_cursor(commit=True) as cursor:
        # Create tenant
        cursor.execute("""
            INSERT INTO Tenant (
                name, address, contact_phone, receipt_prefix,
                president_name, vice_president_name, secretary_name,
                treasurer_name, registration_no, footer_text
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING *
        """, (
            data['name'],
            data['address'],
            data.get('contact_phone'),
            data['receipt_prefix'],
            data.get('president_name'),
            data.get('vice_president_name'),
            data.get('secretary_name'),
            data.get('treasurer_name'),
            data.get('registration_no'),
            data.get('footer_text', 'धन्यवाद! आपल्या योगदानाबद्दल कृतज्ञ आहोत।')
        ))
        
        tenant = cursor.fetchone()
        
        return jsonify(dict(tenant)), 201


@bp.route("/tenants/<int:tenant_id>", methods=["PUT"])
@require_superadmin
def update_tenant(user, tenant_id):
    """Update tenant details"""
    
    data = request.get_json()
    
    with get_db_cursor(commit=True) as cursor:
        update_fields = []
        values = []
        
        allowed_fields = [
            'name', 'address', 'contact_phone', 'receipt_prefix',
            'president_name', 'vice_president_name', 'secretary_name',
            'treasurer_name', 'registration_no', 'footer_text', 'status'
        ]
        
        for field in allowed_fields:
            if field in data:
                update_fields.append(f"{field} = %s")
                values.append(data[field])
        
        if not update_fields:
            return jsonify({"detail": "No fields to update"}), 400
        
        values.append(tenant_id)
        
        query = f"""
            UPDATE Tenant 
            SET {', '.join(update_fields)}, updated_at = now()
            WHERE id = %s
            RETURNING *
        """
        
        cursor.execute(query, values)
        tenant = cursor.fetchone()
        
        if not tenant:
            return jsonify({"detail": "Tenant not found"}), 404
        
        return jsonify(dict(tenant))


@bp.route("/tenants/<int:tenant_id>", methods=["DELETE"])
@require_superadmin
def delete_tenant(user, tenant_id):
    """Delete tenant (soft delete by setting status)"""
    
    if tenant_id == 0:
        return jsonify({"detail": "Cannot delete system tenant"}), 400
    
    with get_db_cursor(commit=True) as cursor:
        cursor.execute("""
            UPDATE Tenant 
            SET status = 'INACTIVE', updated_at = now()
            WHERE id = %s
            RETURNING id
        """, (tenant_id,))
        
        result = cursor.fetchone()
        
        if not result:
            return jsonify({"detail": "Tenant not found"}), 404
        
        return jsonify({"message": "Tenant deactivated"})


@bp.route("/tenants/<int:tenant_id>/users", methods=["GET"])
@require_superadmin
def get_tenant_users(user, tenant_id):
    """Get all users for a specific tenant"""
    
    with get_db_cursor() as cursor:
        cursor.execute("""
            SELECT id, name, email, phone, role, status, created_at
            FROM "User"
            WHERE tenant_id = %s
            ORDER BY created_at DESC
        """, (tenant_id,))
        
        users = cursor.fetchall()
        return jsonify([dict(u) for u in users])


@bp.route("/tenants/<int:tenant_id>/users", methods=["POST"])
@require_superadmin
def create_tenant_user(user, tenant_id):
    """Create a user for a specific tenant"""
    
    data = request.get_json()
    
    # Validate required fields
    if not data.get('name') or not data.get('role'):
        return jsonify({"detail": "Name and role are required"}), 400
    
    if not data.get('email') and not data.get('phone'):
        return jsonify({"detail": "Either email or phone is required"}), 400
    
    with get_db_cursor(commit=True) as cursor:
        cursor.execute("""
            INSERT INTO "User" (
                tenant_id, name, email, phone, role, password_hash, status
            ) VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id, name, email, phone, role, status, created_at
        """, (
            tenant_id,
            data['name'],
            data.get('email'),
            data.get('phone'),
            data['role'],
            data.get('password', 'Admin@123'),
            data.get('status', 'ACTIVE')
        ))
        
        new_user = cursor.fetchone()
        return jsonify(dict(new_user)), 201


@bp.route("/users/<int:user_id>", methods=["PUT"])
@require_superadmin
def update_user(user, user_id):
    """Update user details"""
    
    data = request.get_json()
    
    with get_db_cursor(commit=True) as cursor:
        update_fields = []
        values = []
        
        for field in ['name', 'email', 'phone', 'role', 'status', 'password_hash']:
            if field in data:
                update_fields.append(f"{field} = %s")
                values.append(data[field])
        
        if not update_fields:
            return jsonify({"detail": "No fields to update"}), 400
        
        values.append(user_id)
        
        query = f"""
            UPDATE "User"
            SET {', '.join(update_fields)}, updated_at = now()
            WHERE id = %s
            RETURNING id, name, email, phone, role, status
        """
        
        cursor.execute(query, values)
        updated_user = cursor.fetchone()
        
        if not updated_user:
            return jsonify({"detail": "User not found"}), 404
        
        return jsonify(dict(updated_user))


@bp.route("/stats", methods=["GET"])
@require_superadmin
def get_stats(user):
    """Get overall system statistics"""
    try:
        with get_db_cursor() as cursor:
            # Use separate subqueries to avoid JOIN fan-out that inflates SUM
            cursor.execute("""
                SELECT
                    (SELECT COUNT(*) FROM Tenant WHERE id > 0) AS total_tenants,
                    (SELECT COUNT(*) FROM "User" WHERE role != 'SUPERADMIN') AS total_users,
                    (SELECT COUNT(*) FROM Donation
                        WHERE payment_status != 'CANCELLED') AS total_donations,
                    COALESCE(
                        (SELECT SUM(amount) FROM Donation
                         WHERE payment_status != 'CANCELLED'), 0
                    ) AS total_amount
            """)
            
            stats = cursor.fetchone()
            return jsonify(dict(stats))
    
    except Exception as e:
        print(f"Error getting superadmin stats: {e}")
        return jsonify({
            'total_tenants': 0,
            'total_users': 0,
            'total_donations': 0,
            'total_amount': 0.0
        })
