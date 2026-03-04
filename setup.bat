@echo off
echo ====================================
echo Python FastAPI Backend Setup
echo ====================================
echo.

echo [1/4] Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python not found!
    echo Please install Python from: https://www.python.org/downloads/
    pause
    exit /b 1
)
python --version

echo.
echo [2/4] Creating virtual environment...
if not exist "venv" (
    python -m venv venv
    echo Virtual environment created
) else (
    echo Virtual environment already exists
)

echo.
echo [3/4] Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo [4/4] Installing dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo.
    echo ERROR: pip install failed!
    echo.
    echo Try one of these:
    echo 1. pip install -r requirements.txt --proxy http://your-proxy:port
    echo 2. pip install -r requirements.txt --trusted-host pypi.org --trusted-host files.pythonhosted.org
    echo 3. Ask IT for internal PyPI mirror
    echo.
    pause
    exit /b 1
)

echo.
echo ====================================
echo Setup Complete!
echo ====================================
echo.
echo Next Steps:
echo 1. Configure .env file with your DATABASE_URL
echo 2. Run: psql YOUR_DATABASE_URL -f migrations/001_init.sql
echo 3. Start server: python -m app.main
echo.
echo Or use: start_python_api.bat
echo.
pause
