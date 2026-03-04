@echo off
echo Running migration: 002_add_mandal_officials.sql
echo.
echo Please run this SQL manually in pgAdmin:
echo.
type migrations\002_add_mandal_officials.sql
echo.
echo ========================================
echo Copy the above SQL and execute it in:
echo - Database: ganesh_donations
echo - User: postgres
echo ========================================
pause
