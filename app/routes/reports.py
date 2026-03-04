from flask import Blueprint, request, jsonify
from app.middleware.auth import require_admin
from app.database import get_db_cursor
from datetime import datetime, timedelta

reports_bp = Blueprint('reports', __name__, url_prefix='/reports')

@reports_bp.route('/summary', methods=['GET'])
@require_admin
def get_summary_report(user):
    """Get summary report with date range and filters"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        collector_id = request.args.get('collector_id')
        method = request.args.get('method')
        
        with get_db_cursor() as cursor:
            # Build query
            query = """
                SELECT 
                    COUNT(*) as total_donations,
                    COALESCE(SUM(amount), 0) as total_amount,
                    COALESCE(SUM(CASE WHEN payment_mode = 'UPI' THEN amount ELSE 0 END), 0) as upi_amount,
                    COALESCE(SUM(CASE WHEN payment_mode = 'CASH' THEN amount ELSE 0 END), 0) as cash_amount,
                    COUNT(CASE WHEN payment_mode = 'UPI' THEN 1 END) as upi_count,
                    COUNT(CASE WHEN payment_mode = 'CASH' THEN 1 END) as cash_count
                FROM Donation
                WHERE tenant_id = %s
            """
            params = [tenant_id]
            
            # Add filters
            if start_date:
                query += " AND created_at >= %s"
                params.append(start_date)
            
            if end_date:
                query += " AND created_at <= %s"
                params.append(end_date)
            
            if collector_id:
                query += " AND collector_id = %s"
                params.append(int(collector_id))
            
            if method:
                query += " AND payment_mode = %s"
                params.append(method.upper())
            
            cursor.execute(query, params)
            summary = cursor.fetchone()
            
            # Ensure all values are present even if None
            result = {
                'total_donations': summary['total_donations'] if summary else 0,
                'total_amount': float(summary['total_amount']) if summary else 0.0,
                'upi_amount': float(summary['upi_amount']) if summary else 0.0,
                'cash_amount': float(summary['cash_amount']) if summary else 0.0,
                'upi_count': summary['upi_count'] if summary else 0,
                'cash_count': summary['cash_count'] if summary else 0,
            }
            
            return jsonify(result)
        
    except Exception as e:
        print(f"Error getting summary report: {e}")
        # Return zero values instead of error
        return jsonify({
            'total_donations': 0,
            'total_amount': 0.0,
            'upi_amount': 0.0,
            'cash_amount': 0.0,
            'upi_count': 0,
            'cash_count': 0,
        })

@reports_bp.route('/daily', methods=['GET'])
@require_admin
def get_daily_report(user):
    """Get daily breakdown of donations"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        with get_db_cursor() as cursor:
            query = """
                SELECT 
                    DATE(created_at) as date,
                    COUNT(*) as count,
                    COALESCE(SUM(amount), 0) as total,
                    COALESCE(SUM(CASE WHEN payment_mode = 'UPI' THEN amount ELSE 0 END), 0) as upi_amount,
                    COALESCE(SUM(CASE WHEN payment_mode = 'CASH' THEN amount ELSE 0 END), 0) as cash_amount
                FROM Donation
                WHERE tenant_id = %s
            """
            params = [tenant_id]
            
            if start_date:
                query += " AND created_at >= %s"
                params.append(start_date)
            
            if end_date:
                query += " AND created_at <= %s"
                params.append(end_date)
            
            query += """
                GROUP BY DATE(created_at)
                ORDER BY date DESC
                LIMIT 30
            """
            
            cursor.execute(query, params)
            daily_data = cursor.fetchall()
            
            # Convert dates to ISO format
            for row in daily_data:
                if row.get('date'):
                    row['date'] = row['date'].isoformat()
            
            return jsonify(daily_data)
        
    except Exception as e:
        print(f"Error getting daily report: {e}")
        # Return empty array instead of error
        return jsonify([])

@reports_bp.route('/by-collector', methods=['GET'])
@require_admin
def get_collector_report(user):
    """Get donation statistics by collector"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        with get_db_cursor() as cursor:
            query = """
                SELECT 
                    u.id,
                    u.name,
                    COUNT(d.id) as donation_count,
                    COALESCE(SUM(d.amount), 0) as total_amount,
                    COALESCE(SUM(CASE WHEN d.payment_mode = 'UPI' THEN d.amount ELSE 0 END), 0) as upi_amount,
                    COALESCE(SUM(CASE WHEN d.payment_mode = 'CASH' THEN d.amount ELSE 0 END), 0) as cash_amount
                FROM "User" u
                LEFT JOIN Donation d ON u.id = d.collector_id AND d.tenant_id = %s
            """
            params = [tenant_id]
            
            # Add date filters to JOIN conditions
            if start_date:
                query += " AND d.created_at >= %s"
                params.append(start_date)
            
            if end_date:
                query += " AND d.created_at <= %s"
                params.append(end_date)
            
            # WHERE clause for user filtering
            query += """
                WHERE u.tenant_id = %s AND u.role = 'COLLECTOR'
                GROUP BY u.id, u.name
                ORDER BY total_amount DESC
            """
            params.append(tenant_id)
            
            cursor.execute(query, params)
            collector_data = cursor.fetchall()
            
            return jsonify(collector_data)
        
    except Exception as e:
        print(f"Error getting collector report: {e}")
        # Return empty array instead of error
        return jsonify([])

@reports_bp.route('/top-donors', methods=['GET'])
@require_admin
def get_top_donors(user):
    """Get top donors by total contribution"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        limit = int(request.args.get('limit', 10))
        
        with get_db_cursor() as cursor:
            query = """
                SELECT 
                    donor_name,
                    donor_phone,
                    COUNT(*) as donation_count,
                    COALESCE(SUM(amount), 0) as total_amount,
                    MAX(created_at) as last_donation
                FROM Donation
                WHERE tenant_id = %s AND donor_name IS NOT NULL
            """
            params = [tenant_id]
            
            if start_date:
                query += " AND created_at >= %s"
                params.append(start_date)
            
            if end_date:
                query += " AND created_at <= %s"
                params.append(end_date)
            
            query += """
                GROUP BY donor_name, donor_phone
                ORDER BY total_amount DESC
                LIMIT %s
            """
            params.append(limit)
            
            cursor.execute(query, params)
            top_donors = cursor.fetchall()
            
            # Convert dates to ISO format
            for donor in top_donors:
                if donor.get('last_donation'):
                    donor['last_donation'] = donor['last_donation'].isoformat()
            
            return jsonify(top_donors)
        
    except Exception as e:
        print(f"Error getting top donors: {e}")
        # Return empty array instead of error
        return jsonify([])

@reports_bp.route('/payment-methods', methods=['GET'])
@require_admin
def get_payment_method_analytics(user):
    """Get payment method analytics over time"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        
        with get_db_cursor() as cursor:
            query = """
                SELECT 
                    payment_mode as method,
                    COUNT(*) as count,
                    COALESCE(SUM(amount), 0) as total,
                    COALESCE(AVG(amount), 0) as average
                FROM Donation
                WHERE tenant_id = %s
            """
            params = [tenant_id]
            
            if start_date:
                query += " AND created_at >= %s"
                params.append(start_date)
            
            if end_date:
                query += " AND created_at <= %s"
                params.append(end_date)
            
            query += """
                GROUP BY payment_mode
                ORDER BY total DESC
            """
            
            cursor.execute(query, params)
            method_data = cursor.fetchall()
            
            return jsonify(method_data)
        
    except Exception as e:
        print(f"Error getting payment method analytics: {e}")
        # Return empty array instead of error
        return jsonify([])

@reports_bp.route('/trends', methods=['GET'])
@require_admin
def get_donation_trends(user):
    """Get donation trends for charts"""
    try:
        tenant_id = user['tenant_id']
        
        # Get query parameters - default to last 30 days
        days = int(request.args.get('days', 30))
        
        with get_db_cursor() as cursor:
            query = """
                SELECT 
                    DATE(created_at) as date,
                    payment_mode as method,
                    COUNT(*) as count,
                    COALESCE(SUM(amount), 0) as total
                FROM Donation
                WHERE tenant_id = %s 
                AND created_at >= CURRENT_DATE - INTERVAL %s
                GROUP BY DATE(created_at), payment_mode
                ORDER BY date ASC, payment_mode
            """
            
            # PostgreSQL requires interval as a string like '30 days'
            cursor.execute(query, (tenant_id, f"{days} days"))
            trends = cursor.fetchall()
            
            # Convert dates to ISO format
            for row in trends:
                if row.get('date'):
                    row['date'] = row['date'].isoformat()
            
            return jsonify(trends)
        
    except Exception as e:
        print(f"Error getting donation trends: {e}")
        # Return empty array instead of error
        return jsonify([])
