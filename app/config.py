"""
Configuration Settings Module

Purpose:
- Central location for all application configuration
- Loads environment variables from .env file
- Provides type-safe access to configuration values
- Manages different settings for development, staging, and production environments

Key Features:
1. Environment Variable Loading: Uses python-dotenv to read .env file
2. Type Conversion: Converts string env vars to appropriate types (int, bool, etc.)
3. Default Values: Provides sensible defaults for all settings
4. Network Utilities: Includes helper to get local IP address

Configuration Categories:
- Server Settings: Port, host configuration
- Database Settings: PostgreSQL connection URL
- JWT/Authentication: Token secrets, expiration times
- CORS: Cross-Origin Resource Sharing settings for API access
- File Upload: Directory paths and public URL configuration
"""

# Import operating system utilities for environment variables
import os

# Import socket module for network IP address detection
import socket

# Import dotenv to load environment variables from .env file
from dotenv import load_dotenv

# Load environment variables from .env file into os.environ
# This must be called before accessing any environment variables
load_dotenv()


def get_local_ip():
    """
    Get the local network IP address
    
    Purpose:
    - Determines the machine's IP address on the local network
    - Useful for displaying network access URLs in startup banner
    
    How it works:
    1. Creates a UDP socket (doesn't actually send data)
    2. Connects to a public IP (8.8.8.8 = Google DNS)
    3. Gets the socket's local endpoint address
    4. This reveals which network interface would be used to reach the internet
    
    Returns:
    - str: Local IP address (e.g., "192.168.1.100") or "localhost" on error
    """
    try:
        # Create a UDP socket (SOCK_DGRAM = datagram/UDP)
        # We use UDP because it's connectionless - doesn't actually send packets
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        
        # Connect to Google's public DNS server (8.8.8.8) on port 80
        # This doesn't send any data, just figures out which interface would be used
        s.connect(("8.8.8.8", 80))
        
        # Get the local side of the socket connection (our IP address)
        # getsockname() returns (ip, port) tuple, we want [0] = IP address
        ip = s.getsockname()[0]
        
        # Close the socket to free resources
        s.close()
        
        return ip
        
    except Exception:
        # If anything fails (no network connection, firewall, etc.)
        # Return localhost as fallback
        return "localhost"


class Settings:
    """
    Application Settings Class
    
    Purpose:
    - Container for all application configuration values
    - Loads from environment variables with sensible defaults
    - Makes configuration accessible throughout the application
    
    Design Pattern:
    - All settings are class attributes (not instance attributes)
    - This makes them accessible as Settings.ATTRIBUTE_NAME
    - Values are read once at import time for efficiency
    
    Usage:
    from app.config import settings
    db_url = settings.DATABASE_URL
    """
    
    # ============================================
    # SERVER CONFIGURATION
    # ============================================
    # Port number the server listens on
    # Default: 8080 (common alternative to port 80)
    # Can be overridden by PORT environment variable (useful for cloud platforms)
    PORT = int(os.getenv("PORT", "8080"))
    
    # ============================================
    # DATABASE CONFIGURATION
    # ============================================
    # PostgreSQL connection string in the format:
    # postgresql://username:password@host:port/database
    # Example: postgresql://user:pass@localhost:5432/donations_db
    # This is the primary data store for the application
    DATABASE_URL = os.getenv("DATABASE_URL", "")
    
    # ============================================
    # JWT (JSON Web Token) AUTHENTICATION
    # ============================================
    # Secret key for signing access tokens (short-lived tokens for API requests)
    # CRITICAL: Must be changed in production! Use a long random string
    JWT_SECRET = os.getenv("JWT_SECRET", "your-super-secret-key-change-in-production")
    
    # Secret key for signing refresh tokens (long-lived tokens for getting new access tokens)
    # CRITICAL: Must be different from JWT_SECRET and changed in production
    REFRESH_SECRET = os.getenv("REFRESH_SECRET", "your-refresh-secret-key-change-in-production")
    
    # Algorithm used for JWT encoding/decoding
    # HS256 = HMAC with SHA-256 (symmetric key algorithm)
    JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
    
    # Access token expiration time in minutes
    # Default: 15 minutes (short-lived for security)
    # After expiration, user must use refresh token to get new access token
    ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "15"))
    
    # Refresh token expiration time in days
    # Default: 30 days (long-lived for convenience)
    # After expiration, user must login again with username/password
    REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))
    
    # ============================================
    # CORS (Cross-Origin Resource Sharing)
    # ============================================
    # Which domains are allowed to make API requests
    # "*" = allow all origins (fine for development, restrict in production)
    # Production example: "https://app.example.com,https://admin.example.com"
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")
    
    # ============================================
    # FILE UPLOAD CONFIGURATION
    # ============================================
    # Directory where uploaded files (logos, UPI QR codes, etc.) are stored
    # Default: ./uploads (relative to server.py location)
    # Files are served via /uploads/<filename> endpoint
    UPLOAD_DIR = os.getenv("UPLOAD_DIR", "./uploads")
    
    # Base URL for accessing uploaded files from the internet
    # Used to generate full URLs for uploaded files in API responses
    # Example: If BASE_PUBLIC_URL = "https://api.example.com" and file is "logo.png"
    # The full URL returned will be: "https://api.example.com/uploads/logo.png"
    BASE_PUBLIC_URL = os.getenv("BASE_PUBLIC_URL", "https://ganesh-donations-api.onrender.com")

    # ============================================
    # CLOUDINARY CONFIGURATION (Persistent File Storage)
    # ============================================
    # Render's free tier uses an ephemeral filesystem — files saved to disk are
    # deleted on every server restart/redeploy.  Cloudinary provides a free CDN
    # with permanent URLs so logos and QR codes never disappear.
    #
    # Set these env vars in Render dashboard (or .env locally):
    #   CLOUDINARY_CLOUD_NAME  — from your Cloudinary dashboard
    #   CLOUDINARY_API_KEY     — from your Cloudinary dashboard
    #   CLOUDINARY_API_SECRET  — from your Cloudinary dashboard
    #
    # If all three are set, uploads go to Cloudinary.
    # If they are empty, the server falls back to local disk (dev mode).
    CLOUDINARY_CLOUD_NAME = os.getenv("CLOUDINARY_CLOUD_NAME", "")
    CLOUDINARY_API_KEY    = os.getenv("CLOUDINARY_API_KEY", "")
    CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET", "")
    
    @property
    def cors_origins_list(self):
        """
        Convert CORS_ORIGINS string to a list
        
        Purpose:
        - Parses the CORS_ORIGINS environment variable into a Python list
        - Handles both "*" (allow all) and comma-separated domain lists
        
        Returns:
        - List of allowed origins, e.g., ["*"] or ["https://app1.com", "https://app2.com"]
        
        Examples:
        - CORS_ORIGINS = "*" → ["*"]
        - CORS_ORIGINS = "https://app.com,https://admin.com" → ["https://app.com", "https://admin.com"]
        """
        # If set to wildcard, allow all origins
        if self.CORS_ORIGINS == "*":
            return ["*"]
        
        # Otherwise, split comma-separated list and trim whitespace from each origin
        # Example: "https://a.com, https://b.com" → ["https://a.com", "https://b.com"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]


# Create a singleton instance of Settings
# This instance is imported throughout the application: from app.config import settings
# Using a singleton ensures consistent configuration across all modules
settings = Settings()
