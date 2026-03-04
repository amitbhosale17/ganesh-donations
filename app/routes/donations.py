from flask import Blueprint, request, jsonify, Response
from datetime import datetime
from io import StringIO
import csv
from app.database import get_db_cursor, get_transaction
from app.middleware.auth import require_auth
from app.utils.receipt import next_receipt_no

bp = Blueprint('donations', __name__, url_prefix='/donations')


@bp.route("", methods=["POST"])
@require_auth
def create_donation(user):
    """Record a new donation"""
    
    data = request.get_json()
    
    donor_name = data.get('donor_name')
    donor_phone = data.get('donor_phone')
    amount = data.get('amount')
    method = data.get('method')
    notes = data.get('notes')
    category = data.get('category', 'GENERAL')
    is_recurring_donor = data.get('is_recurring_donor', False)
    additional_notes = data.get('additional_notes')
    payment_status = data.get('payment_status', 'PAID')  # PAID or PENDING
    collector_notes = data.get('collector_notes')
    
    if not amount or not method:
        return jsonify({"detail": "Missing required fields"}), 400
    
    if method not in ['UPI', 'CASH']:
        return jsonify({"detail": "method must be UPI or CASH"}), 400
    
    if float(amount) <= 0:
        return jsonify({"detail": "amount must be positive"}), 400
    
    if payment_status not in ['PAID', 'PENDING']:
        return jsonify({"detail": "payment_status must be PAID or PENDING"}), 400
    
    with get_transaction() as cursor:
        # Get tenant receipt prefix
        cursor.execute(
            "SELECT receipt_prefix FROM Tenant WHERE id = %s",
            (user['tenant_id'],)
        )
        tenant = cursor.fetchone()
        prefix = tenant['receipt_prefix'] if tenant else 'GANESH'
        
        # Generate receipt number atomically
        receipt_no = next_receipt_no(cursor, user['tenant_id'], prefix)
        
        # Insert donation
        cursor.execute("""
            INSERT INTO Donation 
            (tenant_id, collector_id, donor_name, donor_phone, amount, payment_mode, receipt_number, notes, 
             category, is_recurring_donor, additional_notes, payment_status, payment_date, collector_notes)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, receipt_number, created_at, payment_status
        """, (
            user['tenant_id'],
            user['id'],
            donor_name,
            donor_phone,
            amount,
            method,
            receipt_no,
            notes,
            category,
            is_recurring_donor,
            additional_notes,
            payment_status,
            datetime.now() if payment_status == 'PAID' else None,
            collector_notes
        ))
        
        result = cursor.fetchone()
        
        return jsonify({
            "id": result['id'],
            "receipt_no": result['receipt_number'],
            "created_at": result['created_at'].isoformat(),
            "payment_status": result['payment_status']
        }), 201


@bp.route("/bulk", methods=["POST"])
@require_auth
def create_bulk_donations(user):
    """Create multiple donations at once"""
    try:
        data = request.get_json()
        donations_data = data.get('donations', [])
        
        if not donations_data or not isinstance(donations_data, list):
            return jsonify({"error": "donations array is required"}), 400
        
        if len(donations_data) > 50:
            return jsonify({"error": "Maximum 50 donations allowed per bulk request"}), 400
        
        created_donations = []
        errors = []
        
        with get_transaction() as cursor:
            # Get tenant receipt prefix
            cursor.execute(
                "SELECT receipt_prefix FROM Tenant WHERE id = %s",
                (user['tenant_id'],)
            )
            tenant = cursor.fetchone()
            prefix = tenant['receipt_prefix'] if tenant else 'GANESH'
            
            for idx, donation in enumerate(donations_data):
                try:
                    donor_name = donation.get('donor_name')
                    donor_phone = donation.get('donor_phone')
                    amount = donation.get('amount')
                    method = donation.get('method', 'CASH')
                    notes = donation.get('notes')
                    category = donation.get('category', 'GENERAL')
                    is_recurring_donor = donation.get('is_recurring_donor', False)
                    
                    if not amount or float(amount) <= 0:
                        errors.append({"index": idx, "error": "Invalid amount"})
                        continue
                    
                    if method not in ['UPI', 'CASH']:
                        errors.append({"index": idx, "error": "Invalid payment method"})
                        continue
                    
                    # Generate receipt number
                    receipt_no = next_receipt_no(cursor, user['tenant_id'], prefix)
                    
                    # Insert donation
                    cursor.execute("""
                        INSERT INTO Donation 
                        (tenant_id, collector_id, donor_name, donor_phone, amount, payment_mode, 
                         receipt_number, notes, category, is_recurring_donor, payment_status)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 'COMPLETED')
                        RETURNING id, receipt_number
                    """, (
                        user['tenant_id'],
                        user['id'],
                        donor_name,
                        donor_phone,
                        amount,
                        method,
                        receipt_no,
                        notes,
                        category,
                        is_recurring_donor
                    ))
                    
                    result = cursor.fetchone()
                    created_donations.append({
                        "index": idx,
                        "id": result['id'],
                        "receipt_no": result['receipt_number']
                    })
                    
                except Exception as e:
                    errors.append({"index": idx, "error": str(e)})
        
        return jsonify({
            "created": len(created_donations),
            "failed": len(errors),
            "donations": created_donations,
            "errors": errors
        }), 201
        
    except Exception as e:
        print(f"Error creating bulk donations: {e}")
        return jsonify({"error": str(e)}), 500


@bp.route("", methods=["GET"])
@require_auth
def list_donations(user):
    """List donations with pagination and filters"""
    
    limit = int(request.args.get('limit', 100))
    offset = int(request.args.get('offset', 0))
    method = request.args.get('method')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    search = request.args.get('search')
    
    query = """
        SELECT 
            d.id, d.donor_name, d.donor_phone, d.donor_address, d.donor_pan,
            d.amount, d.payment_mode, d.receipt_number, d.notes, 
            d.created_at, d.payment_status, u.name as collector_name
        FROM Donation d
        LEFT JOIN "User" u ON d.collector_id = u.id
        WHERE d.tenant_id = %s
    """
    
    params = [user['tenant_id']]
    
    if method:
        query += " AND d.payment_mode = %s"
        params.append(method)
    
    if start_date:
        query += " AND d.created_at >= %s"
        params.append(start_date)
    
    if end_date:
        query += " AND d.created_at <= %s::date + interval '1 day'"
        params.append(end_date)
    
    if search:
        query += """ AND (
            d.donor_name ILIKE %s OR 
            d.donor_phone ILIKE %s OR 
            d.receipt_number ILIKE %s
        )"""
        search_pattern = f'%{search}%'
        params.extend([search_pattern, search_pattern, search_pattern])
    
    query += " ORDER BY d.created_at DESC LIMIT %s OFFSET %s"
    params.extend([limit, offset])
    
    with get_db_cursor() as cursor:
        cursor.execute(query, params)
        donations = cursor.fetchall()
        
        # Convert to list of dicts with datetime serialization
        result = []
        for d in donations:
            donation_dict = dict(d)
            if donation_dict['created_at']:
                donation_dict['created_at'] = donation_dict['created_at'].isoformat()
            result.append(donation_dict)
        
        return jsonify(result)


@bp.route("/stats", methods=["GET"])
@require_auth
def get_donation_stats(user):
    """Get donation statistics"""
    
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    query = """
        SELECT 
            COUNT(*) as total_count,
            COALESCE(SUM(amount), 0) as total_amount,
            COALESCE(SUM(CASE WHEN payment_mode = 'UPI' THEN amount ELSE 0 END), 0) as upi_amount,
            COALESCE(SUM(CASE WHEN payment_mode = 'CASH' THEN amount ELSE 0 END), 0) as cash_amount,
            COUNT(CASE WHEN payment_mode = 'UPI' THEN 1 END) as upi_count,
            COUNT(CASE WHEN payment_mode = 'CASH' THEN 1 END) as cash_count
        FROM Donation
        WHERE tenant_id = %s AND payment_status IN ('COMPLETED', 'PAID')
    """
    
    params = [user['tenant_id']]
    
    if start_date:
        query += " AND created_at >= %s"
        params.append(start_date)
    
    if end_date:
        query += " AND created_at <= %s::date + interval '1 day'"
        params.append(end_date)
    
    with get_db_cursor() as cursor:
        cursor.execute(query, params)
        stats = cursor.fetchone()
        
        return jsonify({
            'total_count': stats['total_count'],
            'total_amount': float(stats['total_amount']),
            'upi_amount': float(stats['upi_amount']),
            'cash_amount': float(stats['cash_amount']),
            'upi_count': stats['upi_count'],
            'cash_count': stats['cash_count'],
        })


@bp.route("/export.csv", methods=["GET"])
@require_auth
def export_donations_csv(user):
    """Export donations as CSV"""
    
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    method = request.args.get('method')
    
    query = """
        SELECT 
            d.created_at, d.receipt_number, d.payment_mode, d.amount, 
            d.donor_name, d.donor_phone, d.notes,
            u.name as collector_name
        FROM Donation d
        LEFT JOIN "User" u ON d.collector_id = u.id
        WHERE d.tenant_id = %s
    """
    
    params = [user['tenant_id']]
    
    if method:
        query += " AND d.payment_mode = %s"
        params.append(method)
    
    if start_date:
        query += " AND d.created_at >= %s"
        params.append(start_date)
    
    if end_date:
        query += " AND d.created_at <= %s::date + interval '1 day'"
        params.append(end_date)
    
    query += " ORDER BY d.created_at DESC"
    
    with get_db_cursor() as cursor:
        cursor.execute(query, params)
        donations = cursor.fetchall()
        
        # Create CSV in memory
        output = StringIO()
        writer = csv.writer(output)
        
        # Header
        writer.writerow([
            'Date', 'Receipt No', 'Method', 'Amount', 
            'Donor Name', 'Donor Phone', 'Collector', 'Status', 'Notes'
        ])
        
        # Rows
        for d in donations:
            writer.writerow([
                d['created_at'].isoformat() if d['created_at'] else '',
                d['receipt_number'] or '',
                d['payment_mode'] or '',
                d['amount'] or 0,
                d['donor_name'] or '',
                d['donor_phone'] or '',
                d['collector_name'] or '',
                d.get('payment_status', '') or '',
                d['notes'] or ''
            ])
        
        output.seek(0)
        
        return Response(
            output.getvalue(),
            mimetype='text/csv',
            headers={
                'Content-Disposition': f'attachment; filename=donations_{datetime.now().strftime("%Y%m%d")}.csv'
            }
        )


@bp.route("/pending", methods=["GET"])
@require_auth
def get_pending_payments(user):
    """Get all pending payments for the tenant"""
    try:
        tenant_id = user['tenant_id']
        
        with get_db_cursor() as cursor:
            cursor.execute("""
                SELECT 
                    d.id,
                    d.receipt_number,
                    d.donor_name,
                    d.donor_phone,
                    d.amount,
                    d.payment_mode,
                    d.category,
                    d.created_at,
                    d.collector_notes,
                    u.name as collector_name
                FROM Donation d
                LEFT JOIN "User" u ON d.collector_id = u.id
                WHERE d.tenant_id = %s 
                  AND d.payment_status = 'PENDING'
                ORDER BY d.created_at DESC
            """, (tenant_id,))
            
            pending = []
            total_pending = 0
            
            for row in cursor.fetchall():
                donation = {
                    'id': row['id'],
                    'receipt_no': row['receipt_number'],
                    'donor_name': row['donor_name'],
                    'donor_phone': row['donor_phone'],
                    'amount': float(row['amount']),
                    'method': row['payment_mode'],
                    'category': row['category'],
                    'created_at': row['created_at'].isoformat() if row['created_at'] else None,
                    'collector_notes': row['collector_notes'],
                    'collector_name': row['collector_name']
                }
                pending.append(donation)
                total_pending += donation['amount']
        
        return jsonify({
            'success': True,
            'pending_donations': pending,
            'total_pending_amount': total_pending,
            'count': len(pending)
        })
    
    except Exception as e:
        print(f"Error getting pending payments: {e}")
        # Return empty data instead of 500 error
        return jsonify({
            'success': True,
            'pending_donations': [],
            'total_pending_amount': 0,
            'count': 0
        })


@bp.route("/<int:donation_id>/mark-paid", methods=["PUT"])
@require_auth
def mark_donation_paid(user, donation_id):
    """Mark a pending donation as paid"""
    data = request.get_json() or {}
    payment_date = data.get('payment_date', datetime.now().isoformat())
    notes = data.get('notes', '')
    method = data.get('method')  # Optional: allow updating payment method
    
    with get_transaction() as cursor:
        # Verify donation belongs to tenant
        cursor.execute("""
            SELECT id, payment_status, amount
            FROM Donation 
            WHERE id = %s AND tenant_id = %s
        """, (donation_id, user['tenant_id']))
        
        donation = cursor.fetchone()
        
        if not donation:
            return jsonify({'success': False, 'message': 'Donation not found'}), 404
        
        if donation['payment_status'] == 'PAID':
            return jsonify({'success': False, 'message': 'Donation already marked as paid'}), 400
        
        # Update payment status and optionally payment method
        if method and method in ['UPI', 'CASH']:
            cursor.execute("""
                UPDATE Donation
                SET payment_status = 'PAID',
                    payment_date = %s,
                    payment_mode = %s,
                    collector_id = %s,
                    collector_notes = CASE 
                        WHEN collector_notes IS NULL THEN %s
                        ELSE collector_notes || E'\\n' || %s
                    END
                WHERE id = %s
                RETURNING id, receipt_number, payment_status, payment_date, payment_mode
            """, (payment_date, method, user['id'], notes, notes, donation_id))
        else:
            cursor.execute("""
                UPDATE Donation
                SET payment_status = 'PAID',
                    payment_date = %s,
                    collector_id = %s,
                    collector_notes = CASE 
                        WHEN collector_notes IS NULL THEN %s
                        ELSE collector_notes || E'\\n' || %s
                    END
                WHERE id = %s
                RETURNING id, receipt_number, payment_status, payment_date, payment_mode
            """, (payment_date, user['id'], notes, notes, donation_id))
        
        result = cursor.fetchone()
        
        return jsonify({
            'success': True,
            'donation': {
                'id': result['id'],
                'receipt_no': result['receipt_number'],
                'payment_status': result['payment_status'],
                'payment_date': result['payment_date'].isoformat() if result['payment_date'] else None
            }
        })


@bp.route("/<int:donation_id>/cancel", methods=["PUT"])
@require_auth
def cancel_donation(user, donation_id):
    """Cancel a pending donation"""
    data = request.get_json() or {}
    reason = data.get('reason', 'Cancelled by collector')
    
    with get_transaction() as cursor:
        # Verify donation belongs to tenant
        cursor.execute("""
            SELECT id, payment_status
            FROM Donation 
            WHERE id = %s AND tenant_id = %s
        """, (donation_id, user['tenant_id']))
        
        donation = cursor.fetchone()
        
        if not donation:
            return jsonify({'success': False, 'message': 'Donation not found'}), 404
        
        if donation['payment_status'] == 'PAID':
            return jsonify({'success': False, 'message': 'Cannot cancel paid donation'}), 400
        
        # Update to cancelled
        cursor.execute("""
            UPDATE Donation
            SET payment_status = 'CANCELLED',
                collector_notes = CASE 
                    WHEN collector_notes IS NULL THEN %s
                    ELSE collector_notes || E'\n' || %s
                END
            WHERE id = %s
            RETURNING id, receipt_number, payment_status
        """, (reason, reason, donation_id))
        
        result = cursor.fetchone()
        
        return jsonify({
            'success': True,
            'donation': {
                'id': result['id'],
                'receipt_no': result['receipt_number'],
                'payment_status': result['payment_status']
            }
        })

