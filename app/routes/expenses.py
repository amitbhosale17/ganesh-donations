from flask import Blueprint, request, jsonify
from datetime import datetime, date
from app.database import get_db_cursor, get_transaction
from app.middleware.auth import require_auth

bp = Blueprint('expenses', __name__, url_prefix='/expenses')

ALLOWED_ROLES = ('ADMIN', 'COLLECTOR', 'SUPER_ADMIN')


@bp.route("", methods=["POST"])
@require_auth
def create_expense(user):
    """Record a new expense"""
    if user['role'] not in ALLOWED_ROLES:
        return jsonify({"error": "Unauthorized"}), 403

    data = request.get_json() or {}
    amount = data.get('amount')
    note = data.get('note', '').strip()
    category = data.get('category', 'GENERAL').strip().upper() or 'GENERAL'
    expense_date = data.get('expense_date')  # optional ISO date string

    if not amount:
        return jsonify({"error": "amount is required"}), 400
    try:
        amount = float(amount)
        if amount <= 0:
            raise ValueError
    except (TypeError, ValueError):
        return jsonify({"error": "amount must be a positive number"}), 400

    # Parse or default expense_date
    try:
        exp_date = date.fromisoformat(expense_date) if expense_date else date.today()
    except (ValueError, TypeError):
        exp_date = date.today()

    with get_transaction() as cursor:
        cursor.execute("""
            INSERT INTO Expense (tenant_id, recorded_by, amount, category, note, expense_date)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id, amount, category, note, expense_date, created_at
        """, (user['tenant_id'], user['id'], amount, category, note or None, exp_date))

        row = cursor.fetchone()
        return jsonify({
            "id":           row['id'],
            "amount":       float(row['amount']),
            "category":     row['category'],
            "note":         row['note'],
            "expense_date": row['expense_date'].isoformat(),
            "created_at":   row['created_at'].isoformat(),
        }), 201


@bp.route("", methods=["GET"])
@require_auth
def list_expenses(user):
    """List expenses with optional date filters"""
    if user['role'] not in ALLOWED_ROLES:
        return jsonify({"error": "Unauthorized"}), 403

    start_date  = request.args.get('start_date')
    end_date    = request.args.get('end_date')
    limit       = min(int(request.args.get('limit', 200)), 500)
    offset      = int(request.args.get('offset', 0))

    query = """
        SELECT e.id, e.amount, e.category, e.note, e.expense_date, e.created_at,
               u.name AS recorded_by_name
        FROM Expense e
        LEFT JOIN "User" u ON e.recorded_by = u.id
        WHERE e.tenant_id = %s
    """
    params = [user['tenant_id']]

    if start_date:
        query += " AND e.expense_date >= %s"
        params.append(start_date)
    if end_date:
        query += " AND e.expense_date <= %s"
        params.append(end_date)

    count_query = f"SELECT COUNT(*) AS total FROM ({query}) AS c"
    count_params = list(params)

    query += " ORDER BY e.created_at DESC LIMIT %s OFFSET %s"
    params.extend([limit, offset])

    with get_db_cursor() as cursor:
        cursor.execute(count_query, count_params)
        total = cursor.fetchone()['total']

        cursor.execute(query, params)
        rows = cursor.fetchall()
        result = []
        for r in rows:
            result.append({
                "id":               r['id'],
                "amount":           float(r['amount']),
                "category":         r['category'],
                "note":             r['note'],
                "expense_date":     r['expense_date'].isoformat(),
                "created_at":       r['created_at'].isoformat(),
                "recorded_by_name": r['recorded_by_name'],
            })

        return jsonify({"expenses": result, "total": total})


@bp.route("/<int:expense_id>", methods=["DELETE"])
@require_auth
def delete_expense(user, expense_id):
    """Delete an expense (admin only)"""
    if user['role'] not in ('ADMIN', 'SUPER_ADMIN'):
        return jsonify({"error": "Only admins can delete expenses"}), 403

    with get_transaction() as cursor:
        cursor.execute("""
            DELETE FROM Expense
            WHERE id = %s AND tenant_id = %s
            RETURNING id
        """, (expense_id, user['tenant_id']))

        row = cursor.fetchone()
        if not row:
            return jsonify({"error": "Expense not found"}), 404

        return jsonify({"success": True, "deleted_id": row['id']})


@bp.route("/summary", methods=["GET"])
@require_auth
def expense_summary(user):
    """Total expenses for today / overall"""
    if user['role'] not in ALLOWED_ROLES:
        return jsonify({"error": "Unauthorized"}), 403

    tenant_id = user['tenant_id']
    today = date.today()

    with get_db_cursor() as cursor:
        cursor.execute("""
            SELECT
                COALESCE(SUM(CASE WHEN expense_date = %s THEN amount ELSE 0 END), 0) AS today_amount,
                COALESCE(SUM(amount), 0) AS total_amount,
                COUNT(CASE WHEN expense_date = %s THEN 1 END) AS today_count,
                COUNT(*) AS total_count
            FROM Expense
            WHERE tenant_id = %s
        """, (today, today, tenant_id))

        row = cursor.fetchone()
        return jsonify({
            "today_amount":  float(row['today_amount']),
            "total_amount":  float(row['total_amount']),
            "today_count":   row['today_count'],
            "total_count":   row['total_count'],
        })
