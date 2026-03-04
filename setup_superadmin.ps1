# SuperAdmin Setup Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SuperAdmin Setup - Ganesh Donations App" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will create the SuperAdmin role and user." -ForegroundColor Yellow
Write-Host ""
Write-Host "Login Credentials:" -ForegroundColor Green
Write-Host "  Email: superadmin@system.local" -ForegroundColor White
Write-Host "  Password: Super@123" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Continue? (yes/no)"
if ($confirmation -ne 'yes') {
    Write-Host "Cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Running migration..." -ForegroundColor Yellow
Write-Host ""

try {
    python run_migration_003.py
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Setup Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Start API: python server.py" -ForegroundColor White
        Write-Host "2. Start Flutter app" -ForegroundColor White
        Write-Host "3. Login with SuperAdmin credentials" -ForegroundColor White
        Write-Host "4. Create your first mandal!" -ForegroundColor White
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Python not found or error occurred" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run this SQL manually in pgAdmin:" -ForegroundColor Yellow
    Write-Host ""
    Get-Content "migrations\003_add_superadmin.sql" | Write-Host -ForegroundColor White
    Write-Host ""
}

Read-Host "Press Enter to exit"
