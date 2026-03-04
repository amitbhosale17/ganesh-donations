@echo off
echo ========================================
echo SuperAdmin Setup - Ganesh Donations App
echo ========================================
echo.
echo This will create the SuperAdmin role and user.
echo.
echo Login Credentials:
echo   Email: superadmin@system.local
echo   Password: Super@123
echo.
echo Press Ctrl+C to cancel, or
pause

echo.
echo Running migration...
echo.

cd /d "%~dp0"
python run_migration_003.py

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Start API: python server.py
echo 2. Start Flutter app
echo 3. Login with SuperAdmin credentials
echo 4. Create your first mandal!
echo.
pause
