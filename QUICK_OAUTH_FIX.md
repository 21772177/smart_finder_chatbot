# ⚡ Quick OAuth Fix - Step by Step

## ❌ Current Error

**"Missing required parameter: client_id"** and **"Invalid app ID"**

This means OAuth credentials are not configured.

---

## ✅ Fix in 3 Steps

### Step 1: Get YouTube OAuth Credentials

1. Go to: https://console.cloud.google.com/
2. Select project: **buildkit-1695f**
3. **APIs & Services** → **Credentials**
4. **Create Credentials** → **OAuth 2.0 Client ID**
5. If asked, configure OAuth consent screen:
   - User Type: **External**
   - App name: **Smart Finder AI**
   - Your email
   - Save and Continue (skip scopes for now)
   - Add yourself as test user
6. Create OAuth Client:
   - Type: **Web application**
   - Name: **Smart Finder**
   - Redirect URI: `https://buildkit-1695f.web.app/oauth-callback.html`
   - **Copy Client ID and Client Secret**

### Step 2: Get Facebook OAuth Credentials

1. Go to: https://developers.facebook.com/
2. **My Apps** → **Create App**
3. Type: **Consumer**
4. Name: **Smart Finder AI**
5. **Add Product** → **Facebook Login**
6. **Settings** → **Basic**:
   - **Copy App ID**
   - **Copy App Secret** (click Show)
7. **Facebook Login** → **Settings**:
   - Valid OAuth Redirect URIs: `https://buildkit-1695f.web.app/oauth-callback.html`
   - Save

### Step 3: Configure in Firebase

Run these commands (replace with your actual credentials):

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# YouTube
firebase functions:config:set youtube.client_id="YOUR_YOUTUBE_CLIENT_ID_HERE"
firebase functions:config:set youtube.client_secret="YOUR_YOUTUBE_CLIENT_SECRET_HERE"

# Facebook
firebase functions:config:set facebook.app_id="YOUR_FACEBOOK_APP_ID_HERE"
firebase functions:config:set facebook.app_secret="YOUR_FACEBOOK_APP_SECRET_HERE"

# Deploy
firebase deploy --only functions
```

---

## ✅ Verify

After deploying, test:

1. Open: https://buildkit-1695f.web.app
2. Click: "Connect your accounts"
3. Click: "Connect YouTube"
4. Should redirect to Google OAuth (not error page)

---

## 📝 Example Commands

```bash
# Example (replace with your actual values):
firebase functions:config:set youtube.client_id="123456789-abc.apps.googleusercontent.com"
firebase functions:config:set youtube.client_secret="GOCSPX-abcdefghijklmnop"
firebase functions:config:set facebook.app_id="1234567890123456"
firebase functions:config:set facebook.app_secret="abcdef1234567890abcdef1234567890"
firebase deploy --only functions
```

---

## 🎯 That's It!

After this, OAuth will work and users can connect platforms!

