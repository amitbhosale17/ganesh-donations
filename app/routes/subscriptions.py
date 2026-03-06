from flask import Blueprint, request, jsonify
from datetime import datetime, timedelta
from app.database import get_db_cursor, get_transaction
from app.middleware.auth import require_auth

bp = Blueprint('subscriptions', __name__, url_prefix='/subscriptions')


@bp.route("", methods=["GET"])
@require_auth
def get_subscriptions(user):
    """Get all subscription years for the tenant"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    id, subscription_year, start_date, end_date,
                    amount, payment_status, payment_date, created_at
                FROM Subscriptions
                WHERE tenant_id = %s
                ORDER BY subscription_year DESC
            """, (user['tenant_id'],))
            
            subscriptions = []
            for row in cursor.fetchall():
                subscriptions.append({
                    'id': row['id'],
                    'year': row['subscription_year'],
                    'start_date': row['start_date'].isoformat() if row['start_date'] else None,
                    'end_date': row['end_date'].isoformat() if row['end_date'] else None,
                    'amount': float(row['amount']) if row['amount'] else 0,
                    'payment_status': row['payment_status'],
                    'payment_date': row['payment_date'].isoformat() if row['payment_date'] else None,
                    'created_at': row['created_at'].isoformat() if row['created_at'] else None
                })
            
            return jsonify({
                'success': True,
                'subscriptions': subscriptions
            })
    
    except Exception as e:
        print(f"Error getting subscriptions: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/<int:year>", methods=["GET"])
@require_auth
def get_subscription_by_year(user, year):
    """Get subscription details for a specific year"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    id, subscription_year, start_date, end_date,
                    amount, payment_status, payment_date, created_at
                FROM Subscriptions
                WHERE tenant_id = %s AND subscription_year = %s
            """, (user['tenant_id'], year))
            
            row = cursor.fetchone()
            
            if not row:
                return jsonify({
                    'success': False,
                    'error': 'Subscription not found for this year'
                }), 404
            
            # Block access if subscription payment is pending
            if row['payment_status'] != 'PAID':
                return jsonify({
                    'success': False,
                    'error': f'Subscription payment is {row["payment_status"]}. Please complete payment to access this year.',
                    'payment_status': row['payment_status']
                }), 403
            
            subscription = {
                'id': row['id'],
                'year': row['subscription_year'],
                'start_date': row['start_date'].isoformat() if row['start_date'] else None,
                'end_date': row['end_date'].isoformat() if row['end_date'] else None,
                'amount': float(row['amount']) if row['amount'] else 0,
                'payment_status': row['payment_status'],
                'payment_date': row['payment_date'].isoformat() if row['payment_date'] else None,
                'created_at': row['created_at'].isoformat() if row['created_at'] else None
            }
            
            # Get statistics for this year
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_donations,
                    COALESCE(SUM(CASE WHEN payment_status = 'PAID' THEN amount ELSE 0 END), 0) as total_paid,
                    COALESCE(SUM(CASE WHEN payment_status = 'PENDING' THEN amount ELSE 0 END), 0) as total_pending,
                    COUNT(DISTINCT donor_phone) as unique_donors
                FROM Donation
                WHERE tenant_id = %s AND donation_year = %s
            """, (user['tenant_id'], year))
            
            stats = cursor.fetchone()
            subscription['statistics'] = {
                'total_donations': stats['total_donations'],
                'total_paid': float(stats['total_paid']),
                'total_pending': float(stats['total_pending']),
                'unique_donors': stats['unique_donors']
            }
            
            return jsonify({
                'success': True,
                'subscription': subscription
            })
    
    except Exception as e:
        print(f"Error getting subscription by year: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/renew", methods=["POST"])
@require_auth
def renew_subscription(user):
    """Renew subscription for next year"""
    
    if user['role'] != 'ADMIN' and user['role'] != 'SUPER_ADMIN':
        return jsonify({
            'success': False,
            'error': 'Only admins can renew subscriptions'
        }), 403
    
    data = request.get_json() or {}
    year = data.get('year', datetime.now().year + 1)
    amount = data.get('amount', 0)
    
    try:
        with get_transaction() as cursor:
            # Check if subscription already exists or has pending payment
            cursor.execute("""
                SELECT id, payment_status FROM Subscriptions
                WHERE tenant_id = %s AND subscription_year = %s
            """, (user['tenant_id'], year))
            
            existing = cursor.fetchone()
            if existing:
                if existing['payment_status'] == 'PENDING':
                    return jsonify({
                        'success': False,
                        'error': f'Subscription for year {year} already exists with PENDING payment. Please complete or cancel the existing subscription first.'
                    }), 400
                return jsonify({
                    'success': False,
                    'error': f'Subscription for year {year} already exists'
                }), 400
            
            # Create new subscription
            start_date = datetime(year, 1, 1)
            end_date = datetime(year, 12, 31)
            
            cursor.execute("""
                INSERT INTO Subscriptions 
                (tenant_id, subscription_year, start_date, end_date, amount, payment_status, payment_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id, subscription_year, start_date, end_date, amount, payment_status
            """, (user['tenant_id'], year, start_date, end_date, amount, 'PAID', datetime.now()))
            
            subscription = cursor.fetchone()
            
            return jsonify({
                'success': True,
                'subscription': {
                    'id': subscription['id'],
                    'year': subscription['subscription_year'],
                    'start_date': subscription['start_date'].isoformat(),
                    'end_date': subscription['end_date'].isoformat(),
                    'amount': float(subscription['amount']),
                    'payment_status': subscription['payment_status']
                }
            }), 201
    
    except Exception as e:
        print(f"Error renewing subscription: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500


@bp.route("/available-years", methods=["GET"])
@require_auth
def get_available_years(user):
    """Get all years that have subscriptions (for year dropdown)"""
    try:
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    subscription_year as year,
                    payment_status,
                    start_date,
                    end_date
                FROM Subscriptions
                WHERE tenant_id = %s
                ORDER BY subscription_year DESC
            """, (user['tenant_id'],))
            
            years = []
            for row in cursor.fetchall():
                is_current = row['year'] == datetime.now().year
                is_expired = datetime.now().date() > row['end_date'] if row['end_date'] else False
                
                years.append({
                    'year': row['year'],
                    'payment_status': row['payment_status'],
                    'is_current': is_current,
                    'is_expired': is_expired,
                    'can_access': row['payment_status'] == 'PAID'
                })
            
            return jsonify({
                'success': True,
                'years': years
            })
    
    except Exception as e:
        print(f"Error getting available years: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
