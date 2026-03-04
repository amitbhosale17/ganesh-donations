"""
Authentication Utilities

Purpose:
- Provides functions for password hashing and JWT token management
- Handles token creation, signing, and validation
- Implements secure authentication mechanisms

Key Concepts:

1. Password Hashing:
   - NEVER store plain text passwords in database
   - Use one-way hashing (cannot reverse to get original password)
   - Currently using plain text (TODO: CHANGE IN PRODUCTION)
   - Should use bcrypt, argon2, or pbkdf2

2. JWT (JSON Web Token):
   - Compact, URL-safe token format
   - Contains user claims (id, role, expiration)
   - Cryptographically signed to prevent tampering
   - Self-contained (no need to query database for each request)

3. Token Types:
   - Access Token: Short-lived (15 min), used for API requests
   - Refresh Token: Long-lived (30 days), used to get new access tokens

JWT Structure:
   header.payload.signature
   
   Example:
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.  <- Header (algorithm, type)
   eyJpZCI6MSwidGVuYW50X2lkIjoxfQ.        <- Payload (user data)
   SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c  <- Signature (prevents tampering)

Security Notes:
- JWT_SECRET must be kept secret (like a password)
- If JWT_SECRET is compromised, all tokens are compromised
- Tokens cannot be invalidated once issued (until they expire)
- Keep access tokens short-lived to limit damage if stolen
"""

# Import datetime utilities for token expiration
from datetime import datetime, timedelta
# Import Optional type hint
from typing import Optional
# Import JWT library for encoding/decoding tokens
from jose import JWTError, jwt
# Import application settings
from app.config import settings


def hash_password(password: str) -> str:
    """
    Store password as plain text (for simple internal app)
    
    ⚠️ SECURITY WARNING ⚠️
    This function does NOT hash passwords - it stores them as plain text!
    This is EXTREMELY INSECURE and should NEVER be used in production.
    
    Why This is Dangerous:
    - If database is compromised, all passwords are exposed
    - If admin can see database, they can see all passwords
    - Users often reuse passwords across sites
    
    Proper Implementation (use this in production):
    from passlib.hash import bcrypt
    return bcrypt.hash(password)
    
    Why Hashing?
    - One-way function (cannot reverse to get password)
    - Even database admins cannot see passwords
    - Each password gets unique salt (prevents rainbow table attacks)
    
    TODO: Replace with proper bcrypt hashing before production deployment
    
    Parameters:
    - password: Plain text password
    
    Returns:
    - Same password (no hashing applied)
    """
    # WARNING: Returns password unchanged (NO SECURITY)
    return password


def verify_password(plain_password: str, stored_password: str) -> bool:
    """
    Verify password by direct comparison
    
    ⚠️ SECURITY WARNING ⚠️
    This function compares passwords as plain text.
    Should use secure comparison like bcrypt.verify() in production.
    
    Proper Implementation:
    from passlib.hash import bcrypt
    return bcrypt.verify(plain_password, stored_password)
    
    Why Secure Comparison?
    - bcrypt.verify() compares hashed values, not plain text
    - Constant-time comparison (prevents timing attacks)
    - Handles salt automatically
    
    Parameters:
    - plain_password: Password provided by user during login
    - stored_password: Password stored in database (should be hashed)
    
    Returns:
    - True if passwords match, False otherwise
    """
    # WARNING: Direct comparison of plain text passwords
    return plain_password == stored_password


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Create JWT access token
    
    Purpose:
    - Generates short-lived token for API authentication
    - Contains user identity and authorization info
    - Signed with secret key to prevent tampering
    
    Access Token Usage:
    - Included in Authorization header for each API request
    - Header format: "Authorization: Bearer <token>"
    - Server validates token to authenticate user
    - Expires quickly (15 minutes) for security
    
    Token Payload (Claims):
    - id: User's database ID
    - tenant_id: Organization ID (for multi-tenant isolation)
    - role: User's role (VOLUNTEER, COLLECTOR, ADMIN, SUPERADMIN)
    - name: User's display name
    - exp: Expiration timestamp (added automatically)
    
    Parameters:
    - data: Dictionary containing user information (id, tenant_id, role, name)
    - expires_delta: Optional custom expiration time (defaults to 15 minutes)
    
    Returns:
    - Encoded JWT string that can be sent to client
    
    Security:
    - Token is signed with JWT_SECRET (prevents forgery)
    - Cannot be modified without invalidating signature
    - Expiration enforced (old tokens are rejected)
    """
    # Step 1: Create a copy of data to avoid modifying original
    to_encode = data.copy()
    
    # Step 2: Calculate expiration time
    if expires_delta:
        # Use custom expiration if provided
        expire = datetime.utcnow() + expires_delta
    else:
        # Use default expiration from settings (15 minutes)
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    # Step 3: Add expiration to token payload
    # "exp" is a standard JWT claim for expiration time
    # JWT libraries automatically check this during validation
    to_encode.update({"exp": expire})
    
    # Step 4: Encode and sign the token
    # jwt.encode creates header.payload.signature
    # Uses HMAC-SHA256 algorithm with JWT_SECRET
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)
    
    # Step 5: Return the token string
    return encoded_jwt


def create_refresh_token(data: dict) -> str:
    """
    Create JWT refresh token
    
    Purpose:
    - Generates long-lived token for renewing access tokens
    - Allows users to stay logged in without re-entering password
    - Used exclusively for /auth/refresh endpoint
    
    Refresh Token Usage:
    - Sent to /auth/refresh endpoint to get new access token
    - NOT used for API authentication (use access token for that)
    - Stored securely by client (e.g., secure HTTP-only cookie)
    - Lasts 30 days (configurable)
    
    Why Separate Refresh Token?
    - Security: If access token is stolen, damage is limited (expires in 15 min)
    - Convenience: User doesn't need to login with password every 15 minutes
    - Compromise: Long-lived but only useful for one thing (getting access token)
    
    Token Payload:
    - Same as access token (id, tenant_id, role, name)
    - Different expiration time (30 days vs 15 minutes)
    - Signed with different secret (REFRESH_SECRET)
    
    Parameters:
    - data: Dictionary containing user information
    
    Returns:
    - Encoded JWT string with long expiration
    
    Security:
    - Uses separate REFRESH_SECRET from access tokens
    - If one secret is compromised, the other remains secure
    - Client should store securely (not in localStorage)
    """
    # Step 1: Create a copy of data
    to_encode = data.copy()
    
    # Step 2: Calculate expiration (30 days from now)
    # Refresh tokens last much longer than access tokens
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    # Step 3: Add expiration to payload
    to_encode.update({"exp": expire})
    
    # Step 4: Encode and sign with REFRESH_SECRET
    # Note: Uses different secret than access tokens for extra security
    encoded_jwt = jwt.encode(to_encode, settings.REFRESH_SECRET, algorithm=settings.JWT_ALGORITHM)
    
    # Step 5: Return the refresh token
    return encoded_jwt


def decode_token(token: str, secret: str) -> dict:
    """
    Decode and validate JWT token
    
    Purpose:
    - Verifies token signature (ensures it wasn't tampered with)
    - Checks expiration (ensures token is still valid)
    - Extracts user data from token payload
    
    Validation Steps:
    1. Verify signature using secret key
    2. Check expiration time (exp claim)
    3. Validate token structure and format
    
    Parameters:
    - token: JWT string to decode (e.g., "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
    - secret: Secret key used to sign the token (JWT_SECRET or REFRESH_SECRET)
    
    Returns:
    - dict: Decoded payload with user data if valid
    - None: If token is invalid, expired, or malformed
    
    Why Signature Verification Matters:
    - Anyone can create a JWT and claim to be any user
    - Signature proves the token was created by the server (not forged)
    - Only someone with the secret key can create valid signatures
    - If signature doesn't match, token is rejected
    
    Common Reasons for Failure:
    - Token expired (exp claim in the past)
    - Token signature invalid (token was modified or wrong secret)
    - Token malformed (not valid JWT structure)
    - Wrong secret key used for decoding
    
    Example:
        # Decode access token
        payload = decode_token(access_token, settings.JWT_SECRET)
        if payload:
            user_id = payload['id']
            role = payload['role']
        else:
            # Token invalid or expired
            return error
    """
    try:
        # Step 1: Decode and validate token
        # jwt.decode:
        # - Verifies signature matches (proves token is authentic)
        # - Checks expiration (exp claim must be in future)
        # - Validates token structure
        # - Returns payload as dictionary
        payload = jwt.decode(token, secret, algorithms=[settings.JWT_ALGORITHM])
        
        # Step 2: Return decoded payload
        # Contains user data (id, tenant_id, role, name, exp)
        return payload
        
    except JWTError:
        # Token validation failed (expired, invalid signature, malformed, etc.)
        # Return None to indicate invalid token
        # Caller should treat this as unauthenticated request
        return None
