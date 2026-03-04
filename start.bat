@echo off
echo Starting Python FastAPI Backend...
echo.

if not exist "venv" (
    echo ERROR: Virtual environment not found!
    echo Run setup.bat first
    pause
    exit /b 1
)

echo Activating virtual environment...
call venv\Scripts\activate.bat

echo.
echo Starting server on port 8080...
echo API Docs will be available at: http://localhost:8080/docs
echo.

python -m app.main
