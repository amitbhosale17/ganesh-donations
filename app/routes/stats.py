from flask import Blueprint, jsonify
from datetime import datetime, timedelta
from app.database import get_db_cursor
from app.middleware.auth import require_auth

bp = Blueprint('stats', __name__, url_prefix='/stats')


@bp.route("/today", methods=["GET"])
@require_auth
def get_today_stats(user):
    """Get today's donation statistics for current user's tenant"""
    try:
        tenant_id = user['tenant_id']
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        with get_db_cursor() as cursor:
            # Today's stats
            cursor.execute("""
                SELECT 
                    COUNT(*) as count,
                    COALESCE(SUM(amount), 0) as total_amount,
                    COALESCE(SUM(CASE WHEN payment_mode = 'UPI' THEN amount ELSE 0 END), 0) as upi_amount,
                    COALESCE(SUM(CASE WHEN payment_mode = 'CASH' THEN amount ELSE 0 END), 0) as cash_amount
                FROM Donation
                WHERE tenant_id = %s 
                AND created_at >= %s
                AND payment_status IN ('COMPLETED', 'PAID')
            """, (tenant_id, today_start))
            
            today_stats = cursor.fetchone()
            
            # Overall stats
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_count,
                    COALESCE(SUM(amount), 0) as total_amount
                FROM Donation
                WHERE tenant_id = %s
                AND payment_status IN ('COMPLETED', 'PAID')
            """, (tenant_id,))
            
            overall_stats = cursor.fetchone()
        
        return jsonify({
            'today': {
                'count': today_stats['count'],
                'total_amount': float(today_stats['total_amount']),
                'upi_amount': float(today_stats['upi_amount']),
                'cash_amount': float(today_stats['cash_amount']),
            },
            'overall': {
                'count': overall_stats['total_count'],
                'amount': float(overall_stats['total_amount']),
            }
        })
    
    except Exception as e:
        print(f"Error getting stats: {e}")
        # Return zero values instead of 500 error
        return jsonify({
            'today': {
                'count': 0,
                'total_amount': 0.0,
                'upi_amount': 0.0,
                'cash_amount': 0.0,
            },
            'overall': {
                'count': 0,
                'amount': 0.0,
            }
        })


@bp.route("/recent", methods=["GET"])
@require_auth
def get_recent_donations(user):
    """Get recent donations (last 10)"""
    try:
        tenant_id = user['tenant_id']
        
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    d.id,
                    d.donor_name,
                    d.donor_phone,
                    d.amount,
                    d.payment_mode,
                    d.receipt_number,
                    d.created_at,
                    d.payment_status,
                    u.name as collector_name
                FROM Donation d
                LEFT JOIN "User" u ON d.collector_id = u.id
                WHERE d.tenant_id = %s
                ORDER BY d.created_at DESC
                LIMIT 10
            """, (tenant_id,))
            
            donations = cursor.fetchall()
            result = []
            for d in donations:
                donation_dict = dict(d)
                # Convert datetime to ISO format string
                if donation_dict['created_at']:
                    donation_dict['created_at'] = donation_dict['created_at'].isoformat()
                result.append(donation_dict)
            return jsonify(result)
    
    except Exception as e:
        print(f"Error getting recent donations: {e}")
        # Return empty array instead of 500 error
        return jsonify([])
