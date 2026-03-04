# Python Backend Setup Guide

## Prerequisites

- **Python 3.8+** (Python 3.14.2 already installed ✅)
- **PostgreSQL 12+** (with database created)
- **Flutter SDK** (for mobile app)

## Quick Start

### 1. Install Python Dependencies

```powershell
cd c:\Personal\Donation\api_python

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Install all dependencies
pip install -r requirements.txt
```

### 2. Configure Environment Variables

Edit `.env` file with your database credentials:

```env
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost:5432/donation_db

# JWT Configuration
JWT_SECRET=your-super-secret-key-change-this-in-production
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1440

# Server Configuration
PORT=8080
HOST=0.0.0.0
DEBUG=true
```

**Important:** Change the `DATABASE_URL` to match your PostgreSQL setup!

### 3. Create PostgreSQL Database

```powershell
# Create database (run in cmd or PowerShell)
psql -U postgres -c "CREATE DATABASE donation_db;"

# Run migrations
psql -U postgres -d donation_db -f migrations/001_init.sql
```

**Or if psql is not in PATH:**

```powershell
# Using full path to psql (adjust path based on your PostgreSQL installation)
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -c "CREATE DATABASE donation_db;"
& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -U postgres -d donation_db -f migrations/001_init.sql
```

### 4. Run the Backend Server

```powershell
# Make sure you're in api_python directory with venv activated
python -m uvicorn app.main:app --reload --port 8080
```

The API will be available at:
- **Base URL:** http://localhost:8080
- **API Docs:** http://localhost:8080/docs (Swagger UI)
- **Health Check:** http://localhost:8080/health

## Database Schema

The system uses 4 main tables:

1. **Tenant** - Multi-tenant organization details
2. **User** - Collectors and admins  
3. **Donation** - Donation records with offline support
4. **Sync** - Offline sync queue

### Default Admin Account

After running migrations, use these credentials:

- **Username:** admin
- **Password:** Admin@123
- **Tenant:** demo-tenant

**⚠️ Change password immediately in production!**

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login and get JWT token
- `POST /api/auth/refresh` - Refresh access token

### Tenant Management (Admin only)
- `GET /api/tenant` - Get tenant details
- `PUT /api/tenant` - Update tenant info
- `POST /api/tenant/upload-logo` - Upload logo
- `POST /api/tenant/upload-qr` - Upload UPI QR code

### User Management (Admin only)
- `GET /api/users` - List all users
- `POST /api/users` - Create new user
- `DELETE /api/users/:id` - Delete user

### Donations
- `POST /api/donations` - Create donation
- `GET /api/donations` - List donations (with filters)
- `GET /api/donations/stats` - Get statistics
- `GET /api/donations/export` - Export to CSV

## Testing the API

### Using Swagger UI (Recommended)

1. Open http://localhost:8080/docs
2. Click "Authorize" button
3. Login via `/api/auth/login` to get token
4. Copy the `access_token` from response
5. Enter `Bearer <your-token>` in authorization
6. Test any endpoint interactively!

### Using curl

```powershell
# Login
curl -X POST http://localhost:8080/api/auth/login `
  -H "Content-Type: application/json" `
  -d '{"username":"admin","password":"Admin@123","tenant_id":"demo-tenant"}'

# Get tenant info (use token from login response)
curl http://localhost:8080/api/tenant `
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"

# Create donation
curl -X POST http://localhost:8080/api/donations `
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE" `
  -H "Content-Type: application/json" `
  -d '{
    "tenant_id": "demo-tenant",
    "donor_name": "John Doe",
    "amount": 500,
    "payment_method": "cash",
    "phone": "9876543210",
    "address": "Mumbai"
  }'
```

### Using API Tester HTML

Open `api_tester.html` in your browser for a simple UI to test all endpoints.

## Running Flutter App

### Android Emulator

```powershell
cd c:\Personal\Donation\flutter_app

flutter run --dart-define=API_BASE=http://10.0.2.2:8080
```

**Note:** `10.0.2.2` is the emulator's way to access localhost.

### Physical Device (same network)

```powershell
# Find your PC's IP address
ipconfig

# Look for IPv4 Address (e.g., 192.168.1.100)
flutter run --dart-define=API_BASE=http://192.168.1.100:8080
```

## Troubleshooting

### Port Already in Use

```powershell
# Find process using port 8080
netstat -ano | findstr :8080

# Kill the process (replace PID)
taskkill /PID <process_id> /F

# Or use a different port
python -m uvicorn app.main:app --reload --port 8081
```

### Database Connection Issues

1. **Check PostgreSQL is running:**
   ```powershell
   # Windows Services
   Get-Service -Name postgresql*
   ```

2. **Verify database exists:**
   ```powershell
   psql -U postgres -l
   ```

3. **Test connection string:**
   ```powershell
   psql "postgresql://username:password@localhost:5432/donation_db"
   ```

4. **Check DATABASE_URL in .env:**
   - Username and password correct?
   - Database name matches?
   - Host and port correct?

### Import Errors

```powershell
# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall
```

### CORS Issues in Flutter

If you see CORS errors, the backend already has CORS enabled for all origins in development mode. Check:

1. Flutter app is using correct API_BASE URL
2. Backend is running and accessible
3. No proxy/firewall blocking requests

## Production Deployment

### Environment Variables

```env
# Production settings
DEBUG=false
JWT_SECRET=generate-a-long-random-secret-key-here
DATABASE_URL=postgresql://prod_user:strong_password@db.server.com:5432/donation_prod
ALLOWED_ORIGINS=https://yourapp.com,https://admin.yourapp.com
```

### Generate Secure JWT Secret

```powershell
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

### Run with Gunicorn (Production Server)

```powershell
pip install gunicorn

# Run with 4 worker processes
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8080
```

### Docker Deployment

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

## Database Backup

```powershell
# Backup
pg_dump -U postgres donation_db > backup_$(Get-Date -Format "yyyy-MM-dd").sql

# Restore
psql -U postgres donation_db < backup_2024-01-15.sql
```

## Monitoring

### View Logs

The app uses Python's logging module. Check console output for:
- Request logs
- Error traces
- Database queries (in DEBUG mode)

### Health Check

```powershell
curl http://localhost:8080/health
```

Response should be:
```json
{
  "status": "healthy",
  "database": "connected",
  "version": "1.0.0"
}
```

## Support

For issues:
1. Check logs for error messages
2. Verify database connection
3. Ensure all dependencies installed
4. Check `.env` configuration
5. Review API documentation at `/docs`

## Next Steps

1. ✅ Install dependencies
2. ✅ Configure DATABASE_URL in `.env`
3. ✅ Run database migrations
4. ✅ Start backend server
5. ✅ Test API with Swagger UI
6. ✅ Run Flutter app
7. ✅ Change default admin password
8. ✅ Create tenant and collectors
9. ✅ Start collecting donations!
