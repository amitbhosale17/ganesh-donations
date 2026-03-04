# Render Deployment Setup

## Current Status
- Local git repository: ✅ Initialized
- Render remote: ❌ Not configured
- GitHub remote: ❌ Not configured

## Option 1: Deploy via Render Dashboard (FASTEST - Do This Now!)

1. **Login to Render:**
   - Go to: https://dashboard.render.com
   - Login with your account

2. **Find Your Service:**
   - Look for: `ganesh-donations-api`
   - Click on it

3. **Manual Deploy:**
   - Click **"Manual Deploy"** (top right corner)
   - Select: **"Clear build cache & deploy"**
   - Click: **"Deploy"**
   - Wait 2-3 minutes

4. **Verify Deployment:**
   - Watch the logs for: `✅ Server started`
   - Test: https://ganesh-donations-api.onrender.com/health
   - Should return: `{"status": "healthy"}`

## Option 2: Setup Render Git Remote

To enable `git push render master`, you need the Render Git URL:

### Get Render Git URL:
1. Go to Render Dashboard
2. Click your service: `ganesh-donations-api`
3. Go to **Settings** tab
4. Scroll to **"Git Repository"** section
5. Copy the URL (looks like: `https://git.render.com/srv-xxxxx.git`)

### Add Remote:
```bash
cd C:\Personal\Donation\api_python
git remote add render https://git.render.com/srv-YOUR-SERVICE-ID.git
git push render master
```

## Option 3: Deploy via GitHub (Best for Long-term)

### Setup GitHub Repository:
```bash
# 1. Create repo on GitHub: https://github.com/new
# Name: ganesh-donations-api

# 2. Add remote
git remote add origin https://github.com/YOUR_USERNAME/ganesh-donations-api.git

# 3. Push code
git push -u origin master
```

### Connect Render to GitHub:
1. Go to Render Dashboard
2. Click your service
3. Go to **Settings**
4. Find **"Build & Deploy"** section
5. Click **"Connect Repository"**
6. Select your GitHub repo
7. Set branch: `master`
8. Save

Now every push to GitHub will auto-deploy to Render!

## Current Immediate Action

**DO THIS NOW to fix the 404 error:**

1. ✅ Open: https://dashboard.render.com
2. ✅ Click: `ganesh-donations-api`
3. ✅ Click: **"Manual Deploy"** button
4. ✅ Select: "Clear build cache & deploy"
5. ✅ Wait for deployment to complete
6. ✅ Test file upload in app

This will deploy your latest code and fix the 404 error!

---

**After deployment, test:**
- Upload a logo → Should work ✅
- View receipt with logo → Should appear ✅
- No 404 errors in logs ✅
