from flask import Blueprint, request, jsonify
from app.middleware.auth import require_auth, require_admin
from app.database import get_db_cursor

categories_bp = Blueprint('categories', __name__, url_prefix='/categories')

@categories_bp.route('', methods=['GET'])
@require_auth
def get_categories(user):
    """Get all active categories for the tenant"""
    try:
        tenant_id = user['tenant_id']
        
        with get_db_cursor() as cursor:
            # Check if table exists
            cursor.execute("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'donationcategory'
                )
            """)
            table_exists = cursor.fetchone()['exists']
            
            if not table_exists:
                # Return default categories if table doesn't exist
                return jsonify([
                    {"id": 1, "name": "GENERAL", "description": "General Donation", "display_order": 1},
                    {"id": 2, "name": "PRASAD", "description": "Prasad", "display_order": 2},
                    {"id": 3, "name": "DECORATION", "description": "Decoration", "display_order": 3}
                ])
            
            cursor.execute("""
                SELECT id, name, description, display_order
                FROM DonationCategory
                WHERE tenant_id = %s AND is_active = true
                ORDER BY display_order, name
            """, (tenant_id,))
            
            categories = cursor.fetchall()
            
            # If no categories found, return defaults
            if not categories:
                return jsonify([
                    {"id": 1, "name": "GENERAL", "description": "General Donation", "display_order": 1},
                    {"id": 2, "name": "PRASAD", "description": "Prasad", "display_order": 2},
                    {"id": 3, "name": "DECORATION", "description": "Decoration", "display_order": 3}
                ])
            
            return jsonify(categories)
        
    except Exception as e:
        print(f"Error getting categories: {e}")
        # Return default categories on error
        return jsonify([
            {"id": 1, "name": "GENERAL", "description": "General Donation", "display_order": 1},
            {"id": 2, "name": "PRASAD", "description": "Prasad", "display_order": 2},
            {"id": 3, "name": "DECORATION", "description": "Decoration", "display_order": 3}
        ])

@categories_bp.route('', methods=['POST'])
@require_admin
def create_category(user):
    """Create a new category"""
    try:
        tenant_id = user['tenant_id']
        data = request.get_json()
        
        name = data.get('name', '').strip().upper()
        description = data.get('description', '').strip()
        display_order = data.get('display_order', 999)
        
        if not name:
            return jsonify({"error": "Category name is required"}), 400
        
        with get_db_cursor(commit=True) as cursor:
            # Check if category already exists
            cursor.execute("""
                SELECT id FROM DonationCategory
                WHERE tenant_id = %s AND name = %s
            """, (tenant_id, name))
            
            if cursor.fetchone():
                return jsonify({"error": "Category already exists"}), 400
            
            # Insert new category
            cursor.execute("""
                INSERT INTO DonationCategory (tenant_id, name, description, display_order)
                VALUES (%s, %s, %s, %s)
                RETURNING id, name, description, display_order, is_active
            """, (tenant_id, name, description, display_order))
            
            category = cursor.fetchone()
            return jsonify(category), 201
        
    except Exception as e:
        print(f"Error creating category: {e}")
        return jsonify({"error": str(e)}), 500

@categories_bp.route('/<int:category_id>', methods=['PUT'])
@require_admin
def update_category(user, category_id):
    """Update a category"""
    try:
        tenant_id = user['tenant_id']
        data = request.get_json()
        
        with get_db_cursor(commit=True) as cursor:
            # Check if category exists and belongs to tenant
            cursor.execute("""
                SELECT id FROM DonationCategory
                WHERE id = %s AND tenant_id = %s
            """, (category_id, tenant_id))
            
            if not cursor.fetchone():
                return jsonify({"error": "Category not found"}), 404
            
            # Build update query
            updates = []
            params = []
            
            if 'name' in data:
                updates.append("name = %s")
                params.append(data['name'].strip().upper())
            
            if 'description' in data:
                updates.append("description = %s")
                params.append(data['description'].strip())
            
            if 'display_order' in data:
                updates.append("display_order = %s")
                params.append(int(data['display_order']))
            
            if 'is_active' in data:
                updates.append("is_active = %s")
                params.append(bool(data['is_active']))
            
            if not updates:
                return jsonify({"error": "No fields to update"}), 400
            
            params.extend([category_id, tenant_id])
            
            query = f"""
                UPDATE DonationCategory
                SET {', '.join(updates)}
                WHERE id = %s AND tenant_id = %s
                RETURNING id, name, description, display_order, is_active
            """
            
            cursor.execute(query, params)
            category = cursor.fetchone()
            
            return jsonify(category)
        
    except Exception as e:
        print(f"Error updating category: {e}")
        return jsonify({"error": str(e)}), 500

@categories_bp.route('/<int:category_id>', methods=['DELETE'])
@require_admin
def delete_category(user, category_id):
    """Deactivate a category (soft delete)"""
    try:
        tenant_id = user['tenant_id']
        
        with get_db_cursor(commit=True) as cursor:
            # Check if category exists
            cursor.execute("""
                SELECT id FROM DonationCategory
                WHERE id = %s AND tenant_id = %s
            """, (category_id, tenant_id))
            
            if not cursor.fetchone():
                return jsonify({"error": "Category not found"}), 404
            
            # Soft delete - set is_active to false
            cursor.execute("""
                UPDATE DonationCategory
                SET is_active = false
                WHERE id = %s AND tenant_id = %s
            """, (category_id, tenant_id))
            
            return jsonify({"message": "Category deactivated successfully"})
        
    except Exception as e:
        print(f"Error deleting category: {e}")
        return jsonify({"error": str(e)}), 500
