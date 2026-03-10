from flask import Blueprint, request, jsonify
import os
import uuid
import logging
from pathlib import Path
from app.database import get_db_cursor
from app.middleware.auth import require_auth, require_admin
from app.config import settings

bp = Blueprint('tenant', __name__)
logger = logging.getLogger(__name__)

# ──────────────────────────────────────────────────────────────────────────────
# PERSISTENT UPLOAD HELPER
# ──────────────────────────────────────────────────────────────────────────────
# Render's free tier wipes the local disk on every restart/redeploy.
# This helper uploads to Cloudinary when credentials are configured, and falls
# back to local disk otherwise (useful for local development).
#
# Configure Render env vars:
#   CLOUDINARY_CLOUD_NAME / CLOUDINARY_API_KEY / CLOUDINARY_API_SECRET
# ──────────────────────────────────────────────────────────────────────────────

def _upload_to_cloudinary(file_stream, public_id: str, folder: str) -> str:
    """
    Upload a file stream to Cloudinary and return the permanent secure URL.
    Raises RuntimeError if upload fails.
    """
    import cloudinary
    import cloudinary.uploader

    cloudinary.config(
        cloud_name=settings.CLOUDINARY_CLOUD_NAME,
        api_key=settings.CLOUDINARY_API_KEY,
        api_secret=settings.CLOUDINARY_API_SECRET,
        secure=True,
    )

    result = cloudinary.uploader.upload(
        file_stream,
        public_id=public_id,
        folder=folder,
        overwrite=True,           # replace if same public_id (re-upload same tenant)
        resource_type="image",
        invalidate=True,          # bust CDN cache on overwrite
    )
    url = result.get("secure_url")
    if not url:
        raise RuntimeError(f"Cloudinary returned no URL: {result}")
    logger.info(f"☁️  Cloudinary upload OK: {url}")
    return url


def _save_upload(file, tag: str, tenant_id: int) -> str:
    """
    Persist *file* (werkzeug FileStorage) and return a public URL.

    Strategy:
      1. If Cloudinary env vars are set  → upload to Cloudinary (permanent CDN)
      2. Otherwise                        → save to local ./uploads/ dir

    Args:
        file      – werkzeug FileStorage object (already validated, seeked to 0)
        tag       – short label used in filenames / Cloudinary public_id
                    e.g. "logo" or "upi_qr"
        tenant_id – owning tenant's id (used to namespace the file)

    Returns:
        Public URL string
    """
    use_cloudinary = bool(
        settings.CLOUDINARY_CLOUD_NAME
        and settings.CLOUDINARY_API_KEY
        and settings.CLOUDINARY_API_SECRET
    )

    ext = os.path.splitext(file.filename)[1].lower() if file.filename else ".png"

    if use_cloudinary:
        # Use a deterministic public_id so re-uploading the logo always
        # overwrites the same Cloudinary asset (no orphaned old files).
        public_id = f"{tag}_{tenant_id}"
        file.seek(0)
        url = _upload_to_cloudinary(file.stream, public_id=public_id, folder="ganesh_donations")
        return url
    else:
        # Local disk fallback (dev / self-hosted)
        upload_dir = Path(settings.UPLOAD_DIR).resolve()
        upload_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{tag}_{tenant_id}_{uuid.uuid4()}{ext}"
        filepath = upload_dir / filename
        file.seek(0)
        file.save(str(filepath))
        logger.info(f"💾 Local save: {filepath}")
        return f"{settings.BASE_PUBLIC_URL}/uploads/{filename}"


@bp.route("/tenant/self", methods=["GET"])
@require_auth
def get_tenant(user):
    """Get current tenant information"""
    
    with get_db_cursor() as cursor:
        cursor.execute(
            "SELECT * FROM Tenant WHERE id = %s",
            (user['tenant_id'],)
        )
        tenant = cursor.fetchone()
        
        if not tenant:
            return jsonify({"detail": "Tenant not found"}), 404
        
        return jsonify(dict(tenant))


@bp.route("/tenant/self", methods=["PUT"])
@require_admin
def update_tenant(user):
    """Update tenant settings (Admin only)"""
    
    data = request.get_json()
    
    with get_db_cursor(commit=True) as cursor:
        # Build dynamic update query
        update_fields = []
        values = []
        
        allowed_fields = [
            'name', 'address', 'contact_phone', 'contact_email', 'receipt_prefix', 
            'footer_lines', 'locale_default', 'president_name', 'vice_president_name', 
            'secretary_name', 'treasurer_name', 'registration_no', 'footer_text',
            'header_text', 'pan_number', 'office_bearers'
        ]
        
        for field in allowed_fields:
            if field in data and data[field] is not None:
                # Handle JSONB field
                if field == 'office_bearers':
                    import json
                    update_fields.append(f"{field} = %s::jsonb")
                    values.append(json.dumps(data[field]))
                else:
                    update_fields.append(f"{field} = %s")
                    values.append(data[field])
        
        if not update_fields:
            return jsonify({"detail": "No fields to update"}), 400
        
        values.append(user['tenant_id'])
        
        query = f"""
            UPDATE Tenant 
            SET {', '.join(update_fields)}, updated_at = now()
            WHERE id = %s
            RETURNING *
        """
        
        cursor.execute(query, values)
        tenant = cursor.fetchone()
        
        return jsonify(dict(tenant))


@bp.route("/tenant/upload/logo", methods=["POST"])
@require_admin
def upload_logo(user):
    """Upload tenant logo (Admin only). Stores to Cloudinary (persistent) or local disk."""
    try:
        logger.info(f"Logo upload: tenant_id={user['tenant_id']}")

        if 'file' not in request.files:
            return jsonify({"detail": "No file provided"}), 400
        file = request.files['file']
        if file.filename == '':
            return jsonify({"detail": "No file selected"}), 400
        if not file.content_type or not file.content_type.startswith('image/'):
            return jsonify({"detail": f"Only image files allowed. Got: {file.content_type}"}), 400

        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        if file_size > 5 * 1024 * 1024:
            return jsonify({"detail": "File too large. Maximum 5 MB."}), 400
        if file_size < 100:
            return jsonify({"detail": "File appears empty or corrupt."}), 400

        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'):
            return jsonify({"detail": f"Unsupported extension '{ext}'."}), 400

        url = _save_upload(file, tag="logo", tenant_id=user['tenant_id'])

        with get_db_cursor(commit=True) as cursor:
            cursor.execute(
                "UPDATE Tenant SET logo_url = %s, updated_at = now() WHERE id = %s RETURNING id",
                (url, user['tenant_id'])
            )
            if not cursor.fetchone():
                return jsonify({"detail": "Tenant not found"}), 404

        logger.info(f"✅ Logo updated: tenant_id={user['tenant_id']}, url={url}")
        return jsonify({"url": url, "message": "Logo uploaded successfully"}), 200

    except Exception as e:
        logger.error(f"upload_logo error: tenant_id={user.get('tenant_id')}: {e}", exc_info=True)
        return jsonify({"detail": f"Upload failed: {str(e)}"}), 500


@bp.route("/tenant/upload/upi_qr", methods=["POST"])
@require_admin
def upload_upi_qr(user):
    """Upload UPI QR code (Admin only). Stores to Cloudinary (persistent) or local disk."""
    try:
        logger.info(f"UPI QR upload: tenant_id={user['tenant_id']}")

        if 'file' not in request.files:
            return jsonify({"detail": "No file provided"}), 400
        file = request.files['file']
        if file.filename == '':
            return jsonify({"detail": "No file selected"}), 400
        if not file.content_type or not file.content_type.startswith('image/'):
            return jsonify({"detail": f"Only image files allowed. Got: {file.content_type}"}), 400

        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        if file_size > 5 * 1024 * 1024:
            return jsonify({"detail": "File too large. Maximum 5 MB."}), 400
        if file_size < 100:
            return jsonify({"detail": "File appears empty or corrupt."}), 400

        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'):
            return jsonify({"detail": f"Unsupported extension '{ext}'."}), 400

        url = _save_upload(file, tag="upi_qr", tenant_id=user['tenant_id'])

        with get_db_cursor(commit=True) as cursor:
            cursor.execute(
                "UPDATE Tenant SET upi_qr_url = %s, updated_at = now() WHERE id = %s RETURNING id",
                (url, user['tenant_id'])
            )
            if not cursor.fetchone():
                return jsonify({"detail": "Tenant not found"}), 404

        logger.info(f"✅ UPI QR updated: tenant_id={user['tenant_id']}, url={url}")
        return jsonify({"url": url, "message": "UPI QR code uploaded successfully"}), 200

    except Exception as e:
        logger.error(f"upload_upi_qr error: tenant_id={user.get('tenant_id')}: {e}", exc_info=True)
        return jsonify({"detail": f"Upload failed: {str(e)}"}), 500


@bp.route("/tenant/upload/qr_code", methods=["POST"])
@require_admin
def upload_qr_code(user):
    """Upload generic QR code (Admin only). Stores to Cloudinary (persistent) or local disk."""
    try:
        logger.info(f"QR code upload: tenant_id={user['tenant_id']}")

        if 'file' not in request.files:
            return jsonify({"detail": "No file provided"}), 400
        file = request.files['file']
        if file.filename == '':
            return jsonify({"detail": "No file selected"}), 400
        if not file.content_type or not file.content_type.startswith('image/'):
            return jsonify({"detail": "Only image files allowed."}), 400

        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        if file_size > 5 * 1024 * 1024:
            return jsonify({"detail": "File too large. Maximum 5 MB."}), 400
        if file_size < 100:
            return jsonify({"detail": "File appears empty or corrupt."}), 400

        ext = os.path.splitext(file.filename)[1].lower()
        if ext not in ('.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'):
            return jsonify({"detail": f"Unsupported extension '{ext}'."}), 400

        url = _save_upload(file, tag="qr_code", tenant_id=user['tenant_id'])

        with get_db_cursor(commit=True) as cursor:
            cursor.execute(
                "UPDATE Tenant SET qr_code_url = %s, updated_at = now() WHERE id = %s RETURNING id",
                (url, user['tenant_id'])
            )
            if not cursor.fetchone():
                return jsonify({"detail": "Tenant not found"}), 404

        logger.info(f"✅ QR code updated: tenant_id={user['tenant_id']}, url={url}")
        return jsonify({"url": url, "message": "QR code uploaded successfully"}), 200

    except Exception as e:
        logger.error(f"upload_qr_code error: tenant_id={user.get('tenant_id')}: {e}", exc_info=True)
        return jsonify({"detail": f"Upload failed: {str(e)}"}), 500


@bp.route("/users", methods=["GET"])
@require_admin
def list_users(user):
    """List all users in tenant (Admin only)"""
    
    with get_db_cursor() as cursor:
        cursor.execute("""
            SELECT id, name, email, phone, role, status, created_at 
            FROM "User" 
            WHERE tenant_id = %s 
            ORDER BY created_at DESC
        """, (user['tenant_id'],))
        
        users = cursor.fetchall()
        return jsonify([dict(u) for u in users])


@bp.route("/users", methods=["POST"])
@require_admin
def create_user(user):
    """Create new user (Admin only)"""
    
    data = request.get_json()
    
    name = data.get('name')
    email = data.get('email')
    phone = data.get('phone')
    role = data.get('role')
    password = data.get('password')
    
    if not name or not role or not password:
        return jsonify({"detail": "Missing required fields"}), 400
    
    if not email and not phone:
        return jsonify({"detail": "Either email or phone is required"}), 400
    
    from app.utils.auth import hash_password
    password_hash = hash_password(password)
    
    with get_db_cursor(commit=True) as cursor:
        try:
            cursor.execute("""
                INSERT INTO "User" (tenant_id, name, email, phone, role, password_hash)
                VALUES (%s, %s, %s, %s, %s, %s)
                RETURNING id, name, email, phone, role, status, created_at
            """, (
                user['tenant_id'],
                name,
                email,
                phone,
                role,
                password_hash
            ))
            
            created_user = cursor.fetchone()
            return jsonify(dict(created_user)), 201
            
        except Exception as e:
            if "unique" in str(e).lower():
                return jsonify({"detail": "Email or phone already exists"}), 409
            raise


@bp.route("/users/<int:user_id>/status", methods=["PUT"])
@require_admin
def update_user_status(user, user_id):
    """Update user status (Admin only)"""
    
    data = request.get_json()
    new_status = data.get('status')
    
    if new_status not in ['ACTIVE', 'DISABLED']:
        return jsonify({"detail": "Invalid status"}), 400
    
    with get_db_cursor(commit=True) as cursor:
        cursor.execute("""
            UPDATE "User" 
            SET status = %s, updated_at = now()
            WHERE id = %s AND tenant_id = %s
            RETURNING id, name, status
        """, (new_status, user_id, user['tenant_id']))
        
        updated_user = cursor.fetchone()
        
        if not updated_user:
            return jsonify({"detail": "User not found"}), 404
        
        return jsonify(dict(updated_user))
