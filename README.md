# Ganesh Donations API - Python/FastAPI Version

**✅ NO npm REQUIRED - Works on corporate laptops!**

## Quick Start

### 1. Install Python (if not installed)

Download from: https://www.python.org/downloads/

Or check if already installed:
```powershell
python --version
```

### 2. Create Virtual Environment (Recommended)

```powershell
cd c:\Personal\Donation\api_python
python -m venv venv
.\venv\Scripts\Activate.ps1
```

If you get execution policy error:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
.\venv\Scripts\Activate.ps1
```

### 3. Install Dependencies

```powershell
pip install -r requirements.txt
```

**If pip is also blocked**, try:
```powershell
# Use company's internal PyPI mirror (ask IT)
pip install -r requirements.txt --index-url http://your-internal-pypi

# Or install offline (download packages on another machine)
pip download -r requirements.txt -d packages
pip install --no-index --find-links=packages -r requirements.txt
```

### 4. Configure Environment

Update `.env` file with your database connection:
```env
DATABASE_URL=postgresql://user:password@host:5432/ganesh_donations
```

### 5. Setup Database

Same database schema as Node.js version:
```powershell
psql YOUR_DATABASE_URL -f migrations/001_init.sql
```

### 6. Run the Server

```powershell
python -m app.main
```

Or using uvicorn directly:
```powershell
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

## Features

✅ **Same API endpoints** as Node.js version  
✅ **No npm required** - uses pip instead  
✅ **Same database schema**  
✅ **Works with existing Flutter app** (no changes needed)  
✅ **Automatic API documentation** at `/docs`  
✅ **Faster startup** than Node.js  
✅ **Better error messages**  

## Endpoints

All endpoints identical to Node.js version:

- `POST /auth/login`
- `POST /auth/refresh`
- `GET /tenant/self`
- `PUT /tenant/self`
- `POST /tenant/upload/logo`
- `POST /tenant/upload/upi_qr`
- `GET /users`
- `POST /users`
- `POST /donations`
- `GET /donations`
- `GET /donations/stats`
- `GET /donations/export.csv`

## API Documentation

FastAPI provides automatic interactive documentation:

- **Swagger UI**: http://localhost:8080/docs
- **ReDoc**: http://localhost:8080/redoc

## Testing

Same test credentials:

```
Admin:
  Email: admin@ganesh.local
  Password: admin123

Collector:
  Phone: 9876543221
  Password: collector123
```

## Advantages Over Node.js

1. **No npm blockage issues**
2. **Built-in API docs** (Swagger/OpenAPI)
3. **Type validation** (Pydantic)
4. **Better error messages**
5. **Smaller deployment size**
6. **Python often pre-installed on corporate laptops**

## Production Deployment

### Using Gunicorn (Recommended)

```powershell
pip install gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8080
```

### Using Docker

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

## Troubleshooting

### pip install fails

**Option 1: Use company proxy**
```powershell
pip install -r requirements.txt --proxy http://proxy:port
```

**Option 2: Use --trusted-host**
```powershell
pip install -r requirements.txt --trusted-host pypi.org --trusted-host files.pythonhosted.org
```

**Option 3: Offline installation**
```powershell
# On a machine with internet:
pip download -r requirements.txt -d packages

# Copy packages folder to your laptop, then:
pip install --no-index --find-links=packages -r requirements.txt
```

### Database connection fails

Check `.env` DATABASE_URL format:
```
postgresql://username:password@hostname:port/database_name
```

### Import errors

Activate virtual environment:
```powershell
.\venv\Scripts\Activate.ps1
```

## Development

### Run with auto-reload

```powershell
uvicorn app.main:app --reload
```

### Run tests

```powershell
# Install pytest
pip install pytest pytest-asyncio httpx

# Run tests
pytest
```

## Migration from Node.js

The Python version is a **drop-in replacement**:

1. ✅ Same database schema
2. ✅ Same API endpoints
3. ✅ Same authentication (JWT)
4. ✅ Same response format
5. ✅ Flutter app works without changes

Just point your Flutter app to the Python backend!

---

**गणपती बाप्पा मोरया! 🙏**
