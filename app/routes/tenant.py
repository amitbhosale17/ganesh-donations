from flask import Blueprint, request, jsonify
import os
import uuid
from pathlib import Path
from app.database import get_db_cursor
from app.middleware.auth import require_auth, require_admin
from app.config import settings

bp = Blueprint('tenant', __name__)


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
    """
    Upload tenant logo (Admin only)
    
    Edge Cases Handled:
    - Missing file in request
    - Empty filename
    - Invalid file type (non-image)
    - File size too large
    - Disk write errors
    - Permission issues
    - Invalid tenant_id
    """
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        # Log request details for debugging
        logger.info(f"Logo upload request from tenant_id={user['tenant_id']}, user_id={user['id']}")
        
        # Edge Case 1: Check if file is in request
        if 'file' not in request.files:
            logger.warning(f"Logo upload failed: No file in request (tenant_id={user['tenant_id']})")
            return jsonify({"detail": "No file provided"}), 400
        
        file = request.files['file']
        
        # Edge Case 2: Check if filename is empty
        if file.filename == '':
            logger.warning(f"Logo upload failed: Empty filename (tenant_id={user['tenant_id']})")
            return jsonify({"detail": "No file selected"}), 400
        
        # Edge Case 3: Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            logger.warning(f"Logo upload failed: Invalid file type '{file.content_type}' (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"Only image files are allowed. Got: {file.content_type}"}), 400
        
        # Edge Case 4: Check file size (5MB limit)
        file.seek(0, 2)  # Seek to end
        file_size = file.tell()  # Get position (file size)
        file.seek(0)  # Reset to beginning
        
        max_size = 5 * 1024 * 1024  # 5MB
        if file_size > max_size:
            logger.warning(f"Logo upload failed: File too large {file_size} bytes (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"File too large. Maximum size is 5MB. Your file: {file_size / 1024 / 1024:.2f}MB"}), 400
        
        logger.info(f"Logo file validation passed: {file.filename}, size={file_size} bytes, type={file.content_type}")
        
        # Create uploads directory with proper permissions
        upload_dir = Path(settings.UPLOAD_DIR).resolve()
        
        try:
            upload_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Upload directory ready: {upload_dir}")
        except PermissionError as e:
            logger.error(f"Permission denied creating upload directory: {upload_dir}", exc_info=True)
            return jsonify({"detail": "Server configuration error: Cannot create upload directory"}), 500
        
        # Generate unique filename to prevent collisions
        ext = os.path.splitext(file.filename)[1].lower()
        # Sanitize extension
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg']
        if ext not in allowed_extensions:
            logger.warning(f"Logo upload failed: Unsupported extension '{ext}' (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"Unsupported file extension. Allowed: {', '.join(allowed_extensions)}"}), 400
        
        filename = f"logo_{user['tenant_id']}_{uuid.uuid4()}{ext}"
        filepath = upload_dir / filename
        
        # Save file with error handling
        try:
            file.save(str(filepath))
            logger.info(f"✅ Logo saved successfully: {filepath}")
        except Exception as e:
            logger.error(f"Failed to save logo file: {filepath}", exc_info=True)
            return jsonify({"detail": f"Failed to save file: {str(e)}"}), 500
        
        # Verify file was actually saved
        if not filepath.exists():
            logger.error(f"Logo file not found after save: {filepath}")
            return jsonify({"detail": "File save verification failed"}), 500
        
        # Generate public URL
        # Edge Case: Handle both production and development URLs
        url = f"{settings.BASE_PUBLIC_URL}/uploads/{filename}"
        logger.info(f"Logo URL generated: {url}")
        
        # Update database
        with get_db_cursor(commit=True) as cursor:
            try:
                cursor.execute(
                    "UPDATE Tenant SET logo_url = %s, updated_at = now() WHERE id = %s RETURNING id, logo_url",
                    (url, user['tenant_id'])
                )
                result = cursor.fetchone()
                
                if not result:
                    logger.error(f"Tenant not found in database: tenant_id={user['tenant_id']}")
                    # Clean up uploaded file
                    filepath.unlink(missing_ok=True)
                    return jsonify({"detail": "Tenant not found"}), 404
                
                logger.info(f"✅ Logo URL updated in database: tenant_id={user['tenant_id']}, url={url}")
                
            except Exception as e:
                logger.error(f"Database update failed for logo: tenant_id={user['tenant_id']}", exc_info=True)
                # Clean up uploaded file
                filepath.unlink(missing_ok=True)
                return jsonify({"detail": f"Database error: {str(e)}"}), 500
        
        return jsonify({
            "url": url,
            "filename": filename,
            "size": file_size,
            "message": "Logo uploaded successfully"
        }), 200
        
    except Exception as e:
        logger.error(f"Unexpected error in upload_logo: tenant_id={user.get('tenant_id')}", exc_info=True)
        return jsonify({"detail": f"Unexpected error: {str(e)}"}), 500


@bp.route("/tenant/upload/upi_qr", methods=["POST"])
@require_admin
def upload_upi_qr(user):
    """
    Upload UPI QR code (Admin only)
    
    Edge Cases Handled:
    - Missing file in request
    - Empty filename
    - Invalid file type (non-image)
    - File size too large
    - Disk write errors
    - Permission issues
    - Invalid tenant_id
    - QR code validation (optional)
    """
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        # Log request details for debugging
        logger.info(f"UPI QR upload request from tenant_id={user['tenant_id']}, user_id={user['id']}")
        
        # Edge Case 1: Check if file is in request
        if 'file' not in request.files:
            logger.warning(f"UPI QR upload failed: No file in request (tenant_id={user['tenant_id']})")
            return jsonify({"detail": "No file provided"}), 400
        
        file = request.files['file']
        
        # Edge Case 2: Check if filename is empty
        if file.filename == '':
            logger.warning(f"UPI QR upload failed: Empty filename (tenant_id={user['tenant_id']})")
            return jsonify({"detail": "No file selected"}), 400
        
        # Edge Case 3: Validate file type
        if not file.content_type or not file.content_type.startswith('image/'):
            logger.warning(f"UPI QR upload failed: Invalid file type '{file.content_type}' (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"Only image files are allowed. Got: {file.content_type}"}), 400
        
        # Edge Case 4: Check file size (5MB limit)
        file.seek(0, 2)  # Seek to end
        file_size = file.tell()  # Get position (file size)
        file.seek(0)  # Reset to beginning
        
        max_size = 5 * 1024 * 1024  # 5MB
        if file_size > max_size:
            logger.warning(f"UPI QR upload failed: File too large {file_size} bytes (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"File too large. Maximum size is 5MB. Your file: {file_size / 1024 / 1024:.2f}MB"}), 400
        
        # Edge Case 5: Minimum file size (to prevent empty/corrupt files)
        if file_size < 100:  # Less than 100 bytes is suspicious
            logger.warning(f"UPI QR upload failed: File too small {file_size} bytes, possibly corrupt (tenant_id={user['tenant_id']})")
            return jsonify({"detail": "File appears to be empty or corrupt"}), 400
        
        logger.info(f"UPI QR file validation passed: {file.filename}, size={file_size} bytes, type={file.content_type}")
        
        # Create uploads directory with proper permissions
        upload_dir = Path(settings.UPLOAD_DIR).resolve()
        
        try:
            upload_dir.mkdir(parents=True, exist_ok=True)
            logger.info(f"Upload directory ready: {upload_dir}")
        except PermissionError as e:
            logger.error(f"Permission denied creating upload directory: {upload_dir}", exc_info=True)
            return jsonify({"detail": "Server configuration error: Cannot create upload directory"}), 500
        
        # Generate unique filename to prevent collisions
        ext = os.path.splitext(file.filename)[1].lower()
        # Sanitize extension
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg']
        if ext not in allowed_extensions:
            logger.warning(f"UPI QR upload failed: Unsupported extension '{ext}' (tenant_id={user['tenant_id']})")
            return jsonify({"detail": f"Unsupported file extension. Allowed: {', '.join(allowed_extensions)}"}), 400
        
        filename = f"upi_qr_{user['tenant_id']}_{uuid.uuid4()}{ext}"
        filepath = upload_dir / filename
        
        # Save file with error handling
        try:
            file.save(str(filepath))
            logger.info(f"✅ UPI QR saved successfully: {filepath}")
        except Exception as e:
            logger.error(f"Failed to save UPI QR file: {filepath}", exc_info=True)
            return jsonify({"detail": f"Failed to save file: {str(e)}"}), 500
        
        # Verify file was actually saved and has correct size
        if not filepath.exists():
            logger.error(f"UPI QR file not found after save: {filepath}")
            return jsonify({"detail": "File save verification failed"}), 500
        
        saved_size = filepath.stat().st_size
        if saved_size != file_size:
            logger.warning(f"UPI QR file size mismatch: expected={file_size}, saved={saved_size}")
        
        # Generate public URL
        # Edge Case: Handle both production and development URLs
        url = f"{settings.BASE_PUBLIC_URL}/uploads/{filename}"
        logger.info(f"UPI QR URL generated: {url}")
        
        # Update database
        with get_db_cursor(commit=True) as cursor:
            try:
                cursor.execute(
                    "UPDATE Tenant SET upi_qr_url = %s, updated_at = now() WHERE id = %s RETURNING id, upi_qr_url",
                    (url, user['tenant_id'])
                )
                result = cursor.fetchone()
                
                if not result:
                    logger.error(f"Tenant not found in database: tenant_id={user['tenant_id']}")
                    # Clean up uploaded file
                    filepath.unlink(missing_ok=True)
                    return jsonify({"detail": "Tenant not found"}), 404
                
                logger.info(f"✅ UPI QR URL updated in database: tenant_id={user['tenant_id']}, url={url}")
                
            except Exception as e:
                logger.error(f"Database update failed for UPI QR: tenant_id={user['tenant_id']}", exc_info=True)
                # Clean up uploaded file
                filepath.unlink(missing_ok=True)
                return jsonify({"detail": f"Database error: {str(e)}"}), 500
        
        return jsonify({
            "url": url,
            "filename": filename,
            "size": file_size,
            "message": "UPI QR code uploaded successfully"
        }), 200
        
    except Exception as e:
        logger.error(f"Unexpected error in upload_upi_qr: tenant_id={user.get('tenant_id')}", exc_info=True)
        return jsonify({"detail": f"Unexpected error: {str(e)}"}), 500


@bp.route("/tenant/upload/qr_code", methods=["POST"])
@require_admin
def upload_qr_code(user):
    """
    Upload generic QR code (Admin only)
    For tenant customization - any QR code they want to display
    """
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        logger.info(f"QR code upload request from tenant_id={user['tenant_id']}")
        
        if 'file' not in request.files:
            return jsonify({"detail": "No file provided"}), 400
        
        file = request.files['file']
        
        if file.filename == '':
            return jsonify({"detail": "No file selected"}), 400
        
        if not file.content_type or not file.content_type.startswith('image/'):
            return jsonify({"detail": f"Only image files are allowed"}), 400
        
        # Check file size
        file.seek(0, 2)
        file_size = file.tell()
        file.seek(0)
        
        max_size = 5 * 1024 * 1024  # 5MB
        if file_size > max_size:
            return jsonify({"detail": f"File too large. Maximum size is 5MB"}), 400
        
        if file_size < 100:
            return jsonify({"detail": "File appears to be empty or corrupt"}), 400
        
        upload_dir = Path(settings.UPLOAD_DIR).resolve()
        upload_dir.mkdir(parents=True, exist_ok=True)
        
        ext = os.path.splitext(file.filename)[1].lower()
        allowed_extensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg']
        if ext not in allowed_extensions:
            return jsonify({"detail": f"Unsupported file extension"}), 400
        
        filename = f"qr_code_{user['tenant_id']}_{uuid.uuid4()}{ext}"
        filepath = upload_dir / filename
        
        file.save(str(filepath))
        logger.info(f"✅ QR code saved: {filepath}")
        
        url = f"{settings.BASE_PUBLIC_URL}/uploads/{filename}"
        
        # Update database
        with get_db_cursor(commit=True) as cursor:
            cursor.execute(
                "UPDATE Tenant SET qr_code_url = %s, updated_at = now() WHERE id = %s RETURNING id, qr_code_url",
                (url, user['tenant_id'])
            )
            result = cursor.fetchone()
            
            if not result:
                filepath.unlink(missing_ok=True)
                return jsonify({"detail": "Tenant not found"}), 404
            
            logger.info(f"✅ QR code URL updated: tenant_id={user['tenant_id']}")
        
        return jsonify({
            "url": url,
            "filename": filename,
            "size": file_size,
            "message": "QR code uploaded successfully"
        }), 200
        
    except Exception as e:
        logger.error(f"Error in upload_qr_code: {str(e)}", exc_info=True)
        return jsonify({"detail": f"Unexpected error: {str(e)}"}), 500


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
