from flask import Blueprint, request, jsonify
from ..database import get_db_cursor
from ..middleware.auth import require_auth

donors_bp = Blueprint('donors', __name__)

@donors_bp.route('/donors/search', methods=['GET'])
@require_auth
def search_donors(user):
    """Search donors by name or phone number"""
    tenant_id = user['tenant_id']
    query = request.args.get('q', '').strip()
    
    if not query or len(query) < 2:
        return jsonify({'success': False, 'message': 'Search query must be at least 2 characters'}), 400
    
    try:
        with get_db_cursor() as cur:
            # Search by name or phone (case-insensitive, partial match)
            search_pattern = f"%{query}%"
            cur.execute('''
                SELECT DISTINCT
                    donor_name,
                    donor_phone,
                    COUNT(*) as total_donations,
                    SUM(amount) as total_amount,
                    MAX(created_at) as last_donation_date,
                    BOOL_OR(is_recurring_donor) as is_recurring
                FROM Donation
                WHERE tenant_id = %s
                  AND payment_status IN ('COMPLETED', 'PAID')
                  AND (
                    LOWER(donor_name) LIKE LOWER(%s)
                    OR donor_phone LIKE %s
                  )
                GROUP BY donor_name, donor_phone
                ORDER BY last_donation_date DESC
                LIMIT 20
            ''', (tenant_id, search_pattern, search_pattern))
            
            results = []
            for row in cur.fetchall():
                results.append({
                    'donor_name': row['donor_name'],
                    'donor_phone': row['donor_phone'],
                    'total_donations': row['total_donations'],
                    'total_amount': float(row['total_amount']) if row['total_amount'] else 0,
                    'last_donation_date': row['last_donation_date'].isoformat() if row['last_donation_date'] else None,
                    'is_recurring': row['is_recurring']
                })
            
            return jsonify({
                'success': True,
                'donors': results,
                'count': len(results)
            })
            
    except Exception as e:
        print(f"Error searching donors: {e}")
        return jsonify({
            'success': True,
            'donors': [],
            'count': 0
        })


@donors_bp.route('/donors/history', methods=['GET'])
@require_auth
def donor_history(user):
    """Get complete donation history for a specific donor"""
    tenant_id = user['tenant_id']
    donor_name = request.args.get('name', '').strip()
    donor_phone = request.args.get('phone', '').strip()
    
    if not donor_name and not donor_phone:
        return jsonify({'success': False, 'message': 'Either name or phone is required'}), 400
    
    try:
        with get_db_cursor() as cur:
            # Build query based on available parameters
            if donor_phone:
                cur.execute('''
                    SELECT 
                        d.id,
                        d.receipt_number,
                        d.donor_name,
                        d.donor_phone,
                        d.amount,
                        d.payment_mode,
                        d.category,
                        d.payment_status,
                        d.payment_date,
                        d.created_at,
                        d.notes,
                        d.is_recurring_donor,
                        u.name as collector_name
                    FROM Donation d
                    LEFT JOIN "User" u ON d.collector_id = u.id
                    WHERE d.tenant_id = %s
                      AND d.payment_status IN ('COMPLETED', 'PAID')
                      AND d.donor_phone = %s
                    ORDER BY d.created_at DESC
                ''', (tenant_id, donor_phone))
            else:
                cur.execute('''
                    SELECT 
                        d.id,
                        d.receipt_number,
                        d.donor_name,
                        d.donor_phone,
                        d.amount,
                        d.payment_mode,
                        d.category,
                        d.payment_status,
                        d.payment_date,
                        d.created_at,
                        d.notes,
                        d.is_recurring_donor,
                        u.name as collector_name
                    FROM Donation d
                    LEFT JOIN "User" u ON d.collector_id = u.id
                    WHERE d.tenant_id = %s
                      AND d.payment_status IN ('COMPLETED', 'PAID')
                      AND LOWER(d.donor_name) = LOWER(%s)
                    ORDER BY d.created_at DESC
                ''', (tenant_id, donor_name))
            
            donations = []
            total_amount = 0
            paid_amount = 0
            pending_amount = 0
            
            for row in cur.fetchall():
                donation = {
                    'id': row['id'],
                    'receipt_no': row['receipt_number'],
                    'donor_name': row['donor_name'],
                    'donor_phone': row['donor_phone'],
                    'amount': float(row['amount']),
                    'method': row['payment_mode'],
                    'category': row['category'],
                    'payment_status': row['payment_status'],
                    'payment_date': row['payment_date'].isoformat() if row['payment_date'] else None,
                    'created_at': row['created_at'].isoformat() if row['created_at'] else None,
                    'notes': row['notes'],
                    'is_recurring_donor': row['is_recurring_donor'],
                    'collector_name': row['collector_name']
                }
                donations.append(donation)
                
                total_amount += donation['amount']
                if donation['payment_status'] == 'PAID':
                    paid_amount += donation['amount']
                elif donation['payment_status'] == 'PENDING':
                    pending_amount += donation['amount']
            
            return jsonify({
                'success': True,
                'donor': {
                    'name': donations[0]['donor_name'] if donations else donor_name,
                    'phone': donations[0]['donor_phone'] if donations else donor_phone,
                    'is_recurring': donations[0]['is_recurring_donor'] if donations else False
                },
                'summary': {
                    'total_donations': len(donations),
                    'total_amount': total_amount,
                    'paid_amount': paid_amount,
                    'pending_amount': pending_amount
                },
                'donations': donations
            })
            
    except Exception as e:
        print(f"Error getting donor history: {e}")
        return jsonify({
            'success': True,
            'donor': {
                'name': donor_name or '',
                'phone': donor_phone or '',
                'is_recurring': False
            },
            'summary': {
                'total_donations': 0,
                'total_amount': 0.0,
                'paid_amount': 0.0,
                'pending_amount': 0.0
            },
            'donations': []
        })


@donors_bp.route('/donors/recent', methods=['GET'])
@require_auth
def recent_donors(user):
    """Get recently donated donors for quick access"""
    tenant_id = user['tenant_id']
    limit = min(int(request.args.get('limit', 10)), 50)
    
    try:
        with get_db_cursor() as cur:
            cur.execute('''
                SELECT DISTINCT ON (donor_phone, donor_name)
                    donor_name,
                    donor_phone,
                    amount,
                    payment_mode as method,
                    category,
                    is_recurring_donor,
                    created_at
                FROM Donation
                WHERE tenant_id = %s
                  AND payment_status IN ('COMPLETED', 'PAID')
                  AND donor_name IS NOT NULL
                ORDER BY donor_phone, donor_name, created_at DESC
                LIMIT %s
            ''', (tenant_id, limit))
            
            donors = []
            for row in cur.fetchall():
                donors.append({
                    'donor_name': row['donor_name'],
                    'donor_phone': row['donor_phone'],
                    'last_amount': float(row['amount']),
                    'last_method': row['method'],
                    'last_category': row['category'],
                    'is_recurring': row['is_recurring_donor'],
                    'last_donation': row['created_at'].isoformat() if row['created_at'] else None
                })
            
            return jsonify({
                'success': True,
                'donors': donors
            })
            
    except Exception as e:
        print(f"Error getting recent donors: {e}")
        return jsonify({
            'success': True,
            'donors': []
        })
