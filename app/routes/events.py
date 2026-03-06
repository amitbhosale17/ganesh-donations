from flask import Blueprint, request, jsonify
from datetime import datetime
from app.database import get_db_cursor, get_transaction
from app.middleware.auth import require_auth, require_superadmin

bp = Blueprint('events', __name__, url_prefix='/events')


@bp.route("/types", methods=["GET"])
def get_event_types():
    """Get all event types (public endpoint for onboarding)"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    id, name, name_hindi, name_marathi, religion,
                    icon_url, color, is_active
                FROM EventTypes
                WHERE is_active = TRUE
                ORDER BY 
                    CASE religion
                        WHEN 'Hindu' THEN 1
                        WHEN 'Muslim' THEN 2
                        WHEN 'Buddhist' THEN 3
                        WHEN 'Sikh' THEN 4
                        WHEN 'Christian' THEN 5
                        WHEN 'Jain' THEN 6
                        ELSE 7
                    END,
                    name
            """)
            
            event_types = []
            for row in cursor.fetchall():
                event_types.append({
                    'id': row['id'],
                    'name': row['name'],
                    'name_hindi': row['name_hindi'],
                    'name_marathi': row['name_marathi'],
                    'religion': row['religion'],
                    'icon_url': row['icon_url'],
                    'color': row['color'],
                    'is_active': row['is_active']
                })
            
            return jsonify({
                'success': True,
                'event_types': event_types
            })
    
    except Exception as e:
        print(f"Error getting event types: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/types", methods=["POST"])
@require_superadmin
def create_event_type(user):
    """Create new event type (Super Admin only)"""
    data = request.get_json() or {}
    
    name = data.get('name')
    name_hindi = data.get('name_hindi')
    name_marathi = data.get('name_marathi')
    religion = data.get('religion')
    icon_url = data.get('icon_url')
    color = data.get('color', '#4169E1')
    
    if not name or not religion:
        return jsonify({
            'success': False,
            'error': 'name and religion are required'
        }), 400
    
    try:
        with get_transaction() as cursor:
            cursor.execute("""
                INSERT INTO EventTypes 
                (name, name_hindi, name_marathi, religion, icon_url, color)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, name, name_hindi, name_marathi, religion, icon_url, color
            """, (name, name_hindi, name_marathi, religion, icon_url, color))
            
            event_type = cursor.fetchone()
            
            return jsonify({
                'success': True,
                'event_type': {
                    'id': event_type['id'],
                    'name': event_type['name'],
                    'name_hindi': event_type['name_hindi'],
                    'name_marathi': event_type['name_marathi'],
                    'religion': event_type['religion'],
                    'icon_url': event_type['icon_url'],
                    'color': event_type['color']
                }
            }), 201
    
    except Exception as e:
        print(f"Error creating event type: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/types/<int:event_type_id>", methods=["PUT"])
@require_superadmin
def update_event_type(user, event_type_id):
    """Update event type (Super Admin only)"""
    data = request.get_json() or {}
    
    try:
        with get_transaction() as cursor:
            update_fields = []
            values = []
            
            allowed_fields = ['name', 'name_hindi', 'name_marathi', 'religion', 'icon_url', 'color', 'is_active']
            
            for field in allowed_fields:
                if field in data:
                    update_fields.append(f"{field} = %s")
                    values.append(data[field])
            
            if not update_fields:
                return jsonify({
                    'success': False,
                    'error': 'No fields to update'
                }), 400
            
            values.append(event_type_id)
            
            query = f"""
                UPDATE EventTypes 
                SET {', '.join(update_fields)}
                WHERE id = %s
                RETURNING id, name, name_hindi, name_marathi, religion, icon_url, color, is_active
            """
            
            cursor.execute(query, values)
            event_type = cursor.fetchone()
            
            if not event_type:
                return jsonify({
                    'success': False,
                    'error': 'Event type not found'
                }), 404
            
            return jsonify({
                'success': True,
                'event_type': dict(event_type)
            })
    
    except Exception as e:
        print(f"Error updating event type: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/organization-events", methods=["GET"])
@require_auth
def get_organization_events(user):
    """Get all events for the organization"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    oe.id, oe.event_year, oe.start_date, oe.end_date,
                    oe.target_amount, oe.collected_amount, oe.is_active,
                    et.name as event_name, et.name_hindi, et.name_marathi,
                    et.religion, et.color
                FROM OrganizationEvents oe
                JOIN EventTypes et ON oe.event_type_id = et.id
                WHERE oe.tenant_id = %s
                ORDER BY oe.event_year DESC, oe.start_date DESC
            """, (user['tenant_id'],))
            
            events = []
            for row in cursor.fetchall():
                events.append({
                    'id': row['id'],
                    'event_year': row['event_year'],
                    'event_name': row['event_name'],
                    'event_name_hindi': row['name_hindi'],
                    'event_name_marathi': row['name_marathi'],
                    'religion': row['religion'],
                    'color': row['color'],
                    'start_date': row['start_date'].isoformat() if row['start_date'] else None,
                    'end_date': row['end_date'].isoformat() if row['end_date'] else None,
                    'target_amount': float(row['target_amount']) if row['target_amount'] else 0,
                    'collected_amount': float(row['collected_amount']) if row['collected_amount'] else 0,
                    'is_active': row['is_active']
                })
            
            return jsonify({
                'success': True,
                'events': events
            })
    
    except Exception as e:
        print(f"Error getting organization events: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/organization-events", methods=["POST"])
@require_auth
def create_organization_event(user):
    """Create new event for organization (Admin only)"""
    
    if user['role'] not in ['ADMIN', 'SUPER_ADMIN']:
        return jsonify({
            'success': False,
            'error': 'Only admins can create events'
        }), 403
    
    data = request.get_json() or {}
    
    event_type_id = data.get('event_type_id')
    event_year = data.get('event_year')
    start_date = data.get('start_date')
    end_date = data.get('end_date')
    target_amount = data.get('target_amount', 0)
    
    if not all([event_type_id, event_year, start_date, end_date]):
        return jsonify({
            'success': False,
            'error': 'Missing required fields'
        }), 400
    
    # Validate dates
    try:
        start = datetime.fromisoformat(start_date.replace('Z', '+00:00'))
        end = datetime.fromisoformat(end_date.replace('Z', '+00:00'))
        if start > end:
            return jsonify({
                'success': False,
                'error': 'start_date cannot be after end_date'
            }), 400
    except (ValueError, AttributeError) as e:
        return jsonify({
            'success': False,
            'error': f'Invalid date format: {str(e)}. Use YYYY-MM-DD'
        }), 400
    
    try:
        with get_transaction() as cursor:
            cursor.execute("""
                INSERT INTO OrganizationEvents 
                (tenant_id, event_type_id, event_year, start_date, end_date, target_amount)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, event_year, start_date, end_date, target_amount, is_active
            """, (user['tenant_id'], event_type_id, event_year, start_date, end_date, target_amount))
            
            event = cursor.fetchone()
            
            return jsonify({
                'success': True,
                'event': {
                    'id': event['id'],
                    'event_year': event['event_year'],
                    'start_date': event['start_date'].isoformat(),
                    'end_date': event['end_date'].isoformat(),
                    'target_amount': float(event['target_amount']),
                    'is_active': event['is_active']
                }
            }), 201
    
    except Exception as e:
        print(f"Error creating organization event: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
