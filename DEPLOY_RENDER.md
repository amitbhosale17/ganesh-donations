# Deploy to Render.com (Free)

## Quick Setup (5 minutes)

### 1. Create Render Account
- Go to https://render.com
- Sign up with GitHub, GitLab, or email
- Verify your email

### 2. Push Code to GitHub (if not already)
```bash
cd C:\Personal\Donation\api_python
git init
git add .
git commit -m "Initial commit for deployment"
# Create a new repo on GitHub, then:
git remote add origin <your-github-repo-url>
git push -u origin main
```

### 3. Deploy on Render

**Option A: Using Blueprint (Automatic)**
1. Go to https://dashboard.render.com
2. Click "New +" → "Blueprint"
3. Connect your GitHub repo
4. Select the repository with api_python folder
5. Render will detect `render.yaml` and set everything up automatically
6. Click "Apply" - it will create both the web service and PostgreSQL database

**Option B: Manual Setup**
1. **Create PostgreSQL Database:**
   - Dashboard → "New +" → "PostgreSQL"
   - Name: `ganesh-donations-db`
   - Database: `ganesh_donations`
   - User: `ganesh_admin`
   - Plan: Free
   - Create Database

2. **Create Web Service:**
   - Dashboard → "New +" → "Web Service"
   - Connect your GitHub repository
   - Root Directory: `api_python` (if in subdirectory)
   - Environment: Python 3
   - Region: Singapore (or closest to you)
   - Build Command: `pip install -r requirements.txt`
   - Start Command: `python server.py`
   - Plan: Free
   
3. **Set Environment Variables:**
   - In your web service settings → "Environment"
   - Add these variables:
     ```
     DATABASE_URL: <copy from your PostgreSQL database "External Database URL">
     JWT_SECRET_KEY: <generate random string>
     PORT: 8080
     HOST: 0.0.0.0
     ```

4. **Run Migration:**
   - Go to web service → "Shell" tab
   - Run: `python -c "from app.database import get_connection, release_connection; conn = get_connection(); cur = conn.cursor(); migration_sql = open('migrations/001_init.sql', 'r', encoding='utf-8').read(); cur.execute(migration_sql); conn.commit(); cur.close(); release_connection(conn)"`

### 4. Get Your API URL
After deployment completes (2-3 minutes):
- Your API will be available at: `https://ganesh-donations-api.onrender.com`
- Copy this URL

### 5. Update Flutter App
Replace the API URL in your Flutter app:
- File: `flutter_app/lib/core/api_client.dart`
- Change: `http://192.168.0.112:8080`
- To: `https://ganesh-donations-api.onrender.com` (or your actual Render URL)

### 6. Rebuild APK
```bash
cd flutter_app
flutter build apk --debug --split-per-abi --target-platform android-arm64
```

### Notes:
- **Free Tier Limits:**
  - Web service spins down after 15 min of inactivity
  - First request after inactivity takes ~30 seconds to wake up
  - 750 hours/month free (enough for 24/7 if only one service)
  - PostgreSQL: 256 MB storage, 97 free hours/month
  
- **Database Connection:**
  - Render provides DATABASE_URL automatically
  - Format: `postgresql://user:password@host:port/database`

- **Custom Domain (Optional):**
  - Can add your own domain in service settings
  - Free SSL included

## Alternative: Railway.app
If Render doesn't work:
1. Go to https://railway.app
2. Sign up with GitHub
3. New Project → Deploy from GitHub
4. Add PostgreSQL plugin
5. Deploy happens automatically

Your API URL will be like: `https://ganesh-donations-api.up.railway.app`
