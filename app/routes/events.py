from flask import Blueprint, request, jsonify
from datetime import datetime
from app.database import get_db_cursor, get_transaction
from app.middleware.auth import require_auth, require_superadmin

bp = Blueprint('events', __name__, url_prefix='/events')


@bp.route("/types", methods=["GET"])
@require_auth
def get_event_types(user):
    """Get event types filtered by tenant's religion"""
    tenant_id = user.get('tenant_id')
    
    try:
        with get_db_cursor() as cursor:
            # Get tenant's religion
            cursor.execute("""
                SELECT religion FROM Tenant WHERE id = %s
            """, (tenant_id,))
            
            tenant_row = cursor.fetchone()
            if not tenant_row:
                return jsonify({
                    'success': False,
                    'error': 'Tenant not found'
                }), 404
            
            tenant_religion = tenant_row['religion'] or 'Hindu'
            
            # Get event types matching tenant's religion + General
            cursor.execute("""
                SELECT 
                    id, name, name_hindi, name_marathi, religion,
                    icon_url, color, is_active
                FROM EventTypes
                WHERE is_active = TRUE 
                  AND (religion = %s OR religion = 'General')
                ORDER BY 
                    CASE WHEN religion = %s THEN 0 ELSE 1 END,
                    name
            """, (tenant_religion, tenant_religion))
            
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
                'event_types': event_types,
                'tenant_religion': tenant_religion
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
    
    valid_religions = ['Hindu', 'Muslim', 'Buddhist', 'Sikh', 'Christian', 'Jain', 'General']
    if religion not in valid_religions:
        return jsonify({
            'success': False,
            'error': f'Invalid religion. Must be one of: {", ".join(valid_religions)}'
        }), 400
    
    try:
        with get_transaction() as cursor:
            cursor.execute("""
                INSERT INTO EventTypes 
                (name, name_hindi, name_marathi, religion, icon_url, color)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, name, religion
            """, (name, name_hindi, name_marathi, religion, icon_url, color))
            
            event_type = cursor.fetchone()
            
            return jsonify({
                'success': True,
                'event_type': {
                    'id': event_type['id'],
                    'name': event_type['name'],
                    'religion': event_type['religion']
                }
            }), 201
    
    except Exception as e:
        print(f"Error creating event type: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/organization-events", methods=["GET"])
@require_auth
def get_organization_events(user):
    """Get all events for the organization"""
    tenant_id = user.get('tenant_id')
    
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    oe.id, oe.event_type_id, oe.event_year,
                    oe.start_date, oe.end_date, oe.target_amount,
                    oe.collected_amount, oe.is_active,
                    et.name, et.name_hindi, et.name_marathi,
                    et.religion, et.color,
                    COUNT(d.id) as donation_count
                FROM OrganizationEvents oe
                JOIN EventTypes et ON oe.event_type_id = et.id
                LEFT JOIN Donation d ON d.event_id = oe.id AND d.payment_status IN ('PAID', 'COMPLETED')
                WHERE oe.tenant_id = %s
                GROUP BY oe.id, oe.event_type_id, oe.event_year, oe.start_date, oe.end_date,
                         oe.target_amount, oe.collected_amount, oe.is_active,
                         et.name, et.name_hindi, et.name_marathi, et.religion, et.color
                ORDER BY oe.event_year DESC, oe.start_date DESC
            """, (tenant_id,))
            
            events = []
            for row in cursor.fetchall():
                events.append({
                    'id': row['id'],
                    'event_type_id': row['event_type_id'],
                    'event_year': row['event_year'],
                    'name': row['name'],
                    'name_hindi': row['name_hindi'],
                    'name_marathi': row['name_marathi'],
                    'religion': row['religion'],
                    'color': row['color'],
                    'start_date': row['start_date'].isoformat(),
                    'end_date': row['end_date'].isoformat(),
                    'target_amount': float(row['target_amount']),
                    'collected_amount': float(row['collected_amount']),
                    'donation_count': row['donation_count'],
                    'is_active': row['is_active'],
                    'progress_percentage': (float(row['collected_amount']) / float(row['target_amount']) * 100) 
                                          if float(row['target_amount']) > 0 else 0
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
    tenant_id = user.get('tenant_id')
    
    # Only admins can create events
    if user.get('role') not in ['ADMIN', 'SUPERADMIN']:
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
    
    # Validate required fields
    if not all([event_type_id, event_year, start_date, end_date]):
        return jsonify({
            'success': False,
            'error': 'event_type_id, event_year, start_date, and end_date are required'
        }), 400
    
    # Validate dates
    try:
        start_dt = datetime.strptime(start_date, '%Y-%m-%d').date()
        end_dt = datetime.strptime(end_date, '%Y-%m-%d').date()
        
        if start_dt > end_dt:
            return jsonify({
                'success': False,
                'error': 'start_date must be before or equal to end_date'
            }), 400
    except ValueError as e:
        return jsonify({
            'success': False,
            'error': f'Invalid date format: {str(e)}. Use YYYY-MM-DD'
        }), 400
    
    try:
        with get_transaction() as cursor:
            # Verify event type matches tenant religion
            cursor.execute("""
                SELECT t.religion, et.religion as event_religion
                FROM Tenant t, EventTypes et
                WHERE t.id = %s AND et.id = %s
            """, (tenant_id, event_type_id))
            
            result = cursor.fetchone()
            if not result:
                return jsonify({
                    'success': False,
                    'error': 'Invalid event type'
                }), 400
            
            tenant_religion = result['religion'] or 'Hindu'
            event_religion = result['event_religion']
            
            # Allow if religions match or event is General
            if event_religion != tenant_religion and event_religion != 'General':
                return jsonify({
                    'success': False,
                    'error': f'Cannot create {event_religion} event. Your organization is {tenant_religion}'
                }), 403
            
            # Create event
            cursor.execute("""
                INSERT INTO OrganizationEvents 
                (tenant_id, event_type_id, event_year, start_date, end_date, target_amount)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, event_year, start_date, end_date, target_amount, is_active
            """, (tenant_id, event_type_id, event_year, start_date, end_date, target_amount))
            
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
        error_msg = str(e)
        print(f"Error creating organization event: {error_msg}")
        
        # Handle unique constraint violation
        if 'unique constraint' in error_msg.lower() or 'duplicate' in error_msg.lower():
            return jsonify({
                'success': False,
                'error': 'Event already exists for this year'
            }), 409
        
        return jsonify({
            'success': False,
            'error': error_msg
        }), 500


@bp.route("/organization-events/<int:event_id>", methods=["PUT"])
@require_auth
def update_organization_event(user, event_id):
    """Update event details (Admin only)"""
    tenant_id = user.get('tenant_id')
    
    if user.get('role') not in ['ADMIN', 'SUPERADMIN']:
        return jsonify({
            'success': False,
            'error': 'Only admins can update events'
        }), 403
    
    data = request.get_json() or {}
    
    try:
        with get_transaction() as cursor:
            # Verify event belongs to tenant
            cursor.execute("""
                SELECT id FROM OrganizationEvents
                WHERE id = %s AND tenant_id = %s
            """, (event_id, tenant_id))
            
            if not cursor.fetchone():
                return jsonify({
                    'success': False,
                    'error': 'Event not found'
                }), 404
            
            # Update fields
            updates = []
            params = []
            
            if 'target_amount' in data:
                updates.append("target_amount = %s")
                params.append(data['target_amount'])
            
            if 'is_active' in data:
                updates.append("is_active = %s")
                params.append(data['is_active'])
            
            if not updates:
                return jsonify({
                    'success': False,
                    'error': 'No fields to update'
                }), 400
            
            params.extend([event_id, tenant_id])
            
            cursor.execute(f"""
                UPDATE OrganizationEvents
                SET {', '.join(updates)}, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s AND tenant_id = %s
                RETURNING id
            """, params)
            
            return jsonify({
                'success': True,
                'message': 'Event updated successfully'
            })
    
    except Exception as e:
        print(f"Error updating event: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
