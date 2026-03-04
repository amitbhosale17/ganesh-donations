# PowerShell script to run the Donation Management API (Flask)

Write-Host "🚀 Starting Donation Management API (Flask)..." -ForegroundColor Cyan

# Check if virtual environment exists
if (!(Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "❌ Virtual environment not found. Creating..." -ForegroundColor Yellow
    python -m venv venv
    Write-Host "✅ Virtual environment created" -ForegroundColor Green
}

# Activate virtual environment
Write-Host "📦 Activating virtual environment..." -ForegroundColor Cyan
& .\venv\Scripts\Activate.ps1

# Check if dependencies are installed
Write-Host "📦 Checking dependencies..." -ForegroundColor Cyan
$installed = & python -c "import flask; print('ok')" 2>$null
if ($installed -ne "ok") {
    Write-Host "📥 Installing dependencies..." -ForegroundColor Yellow
    pip install -r requirements.txt
    Write-Host "✅ Dependencies installed" -ForegroundColor Green
}

# Check if .env exists
if (!(Test-Path ".env")) {
    Write-Host "⚠️  .env file not found!" -ForegroundColor Red
    Write-Host "Please create .env file with DATABASE_URL and other settings" -ForegroundColor Yellow
    Write-Host "See .env.example for reference" -ForegroundColor Yellow
    exit 1
}

# Load environment variables
Write-Host "⚙️  Loading environment variables..." -ForegroundColor Cyan

# Start the server
Write-Host "🌐 Starting Flask server..." -ForegroundColor Green
Write-Host ""
Write-Host "API Server: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Health Check: http://localhost:8080/health" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Run Flask app with Waitress (production-ready)
python server.py
