@echo off
echo ========================================
echo Fixing Receipt Number Issue
echo ========================================
echo.

REM Check if PostgreSQL is accessible
psql --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: psql command not found. Please install PostgreSQL or add it to PATH.
    pause
    exit /b 1
)

echo Running fix_receipt_sequence.sql...
echo.

REM Run the SQL script
psql -h localhost -U postgres -d donations_db -f fix_receipt_sequence.sql

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo SUCCESS! Receipt sequence table created
    echo ========================================
    echo.
    echo Next steps:
    echo 1. Restart the Python API server
    echo 2. Test creating a new donation
    echo 3. Receipt numbers should now work properly
) else (
    echo.
    echo ========================================
    echo ERROR: Failed to run SQL script
    echo ========================================
    echo Please check:
    echo 1. PostgreSQL is running
    echo 2. Database 'donations_db' exists
    echo 3. User 'postgres' has access
)

echo.
pause
