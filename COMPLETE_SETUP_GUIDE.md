# 🚀 Complete Setup Guide - Add All API Keys & OAuth Credentials

> **⚠️ IMPORTANT:** This guide is for **YOU (the developer)** to set up ONCE. End users don't need to do any of this - they just connect their accounts via simple OAuth buttons!
>
> **For details on Developer vs User setup, see:** [`DEVELOPER_VS_USER_SETUP.md`](DEVELOPER_VS_USER_SETUP.md)

This guide will walk you through setting up **all required API keys and OAuth credentials** step-by-step so your chatbot works fully.

---

## 📋 Overview

**Currently Configured:**
- ✅ Gemini API Key
- ✅ OpenAI API Key

**Missing (Need to Configure):**
- ❌ YouTube OAuth (Client ID + Secret)
- ❌ Instagram OAuth (Client ID + Secret)
- ❌ Facebook OAuth (App ID + Secret)
- ❌ YouTube Data API Key
- ❌ Google Maps API Key
- ❌ Google OAuth (Optional - for Timeline)

---

## 🎯 Step-by-Step Setup

### Step 1: YouTube OAuth Credentials

#### 1.1 Create YouTube OAuth Client

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **buildkit-1695f** (or create new)
3. Go to **APIs & Services** → **Credentials**
4. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
5. If prompted, configure OAuth consent screen:
   - User Type: **External** (or Internal if using Google Workspace)
   - App name: **Smart Finder Chatbot**
   - User support email: Your email
   - Developer contact: Your email
   - Click **Save and Continue**
   - Scopes: Click **Add or Remove Scopes**
     - Select: `https://www.googleapis.com/auth/youtube.readonly`
     - Click **Update** → **Save and Continue**
   - Test users: Add your email (for testing)
   - Click **Save and Continue** → **Back to Dashboard**

6. Create OAuth Client ID:
   - Application type: **Web application**
   - Name: **Smart Finder YouTube OAuth**
   - Authorized redirect URIs:
     ```
     https://buildkit-1695f.web.app/auth/youtube/callback
     http://localhost:5000/auth/youtube/callback (for local testing)
     ```
   - Click **Create**
   - **Copy the Client ID and Client Secret** (you'll need these!)

#### 1.2 Configure in Firebase

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# Set YouTube OAuth credentials
firebase functions:config:set youtube.client_id="402603487375-jf4rjbdpjinupif0o7f8ginrhb0gg1pf.apps.googleusercontent.com"
firebase functions:config:set youtube.client_secret="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"
```

**Replace `YOUR_YOUTUBE_CLIENT_ID_HERE` and `YOUR_YOUTUBE_CLIENT_SECRET_HERE` with actual values from step 1.1**

---

### Step 2: YouTube Data API Key

#### 2.1 Enable YouTube Data API

1. In [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services** → **Library**
3. Search for **"YouTube Data API v3"**
4. Click on it and click **Enable**

#### 2.2 Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API Key**
3. Copy the API key
4. (Optional) Click **Restrict Key**:
   - Application restrictions: **HTTP referrers**
   - Add: `https://buildkit-1695f.web.app/*`
   - API restrictions: **Restrict key** → Select **YouTube Data API v3**
   - Click **Save**

#### 2.3 Configure in Firebase

```bash
firebase functions:config:set youtube.key="AIzaSyCpQL_n3PqlG_bOshGi1kD2DBz7H7qtJe4"
```

**Replace `YOUR_YOUTUBE_API_KEY_HERE` with the API key from step 2.2**

---

### Step 3: Instagram OAuth Credentials

#### 3.1 Create Instagram App

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Click **My Apps** → **Create App**
3. Choose **Consumer** or **Business** → Click **Next**
4. Fill in:
   - App Name: **Smart Finder Chatbot**
   - App Contact Email: Your email
   - Click **Create App**

#### 3.2 Add Instagram Basic Display

1. In your app dashboard, click **Add Product**
2. Find **Instagram Basic Display** → Click **Set Up**
3. Go to **Basic Display** → **Basic Display** in left menu
4. Click **Create New App** (if needed)
5. Fill in:
   - Valid OAuth Redirect URIs:
     ```
     https://buildkit-1695f.web.app/auth/instagram/callback
     ```
   - Deauthorize Callback URL:
     ```
     https://buildkit-1695f.web.app/auth/instagram/deauthorize
     ```
   - Data Deletion Request URL (optional):
     ```
     https://buildkit-1695f.web.app/auth/instagram/data-deletion
     ```
   - Click **Save Changes**

#### 3.3 Get Client ID and Secret

1. In **Basic Display** settings, you'll see:
   - **Instagram App ID** (this is your Client ID)
   - **Instagram App Secret** (this is your Client Secret)
2. **Copy both values**

#### 3.4 Configure in Firebase

```bash
firebase functions:config:set instagram.client_id="1874072056536563"
firebase functions:config:set instagram.client_secret="c4042cef188f10609f94849e64aa2c0f"
```

**Replace with actual values from step 3.3**

---

### Step 4: Facebook OAuth Credentials

#### 4.1 Use Same Facebook App (or Create New)

1. In [Facebook Developers](https://developers.facebook.com/)
2. Use the same app from Step 3, or create a new one
3. Go to **Settings** → **Basic**
4. You'll see:
   - **App ID**
   - **App Secret** (click **Show** to reveal)

#### 4.2 Add Facebook Login Product

1. Click **Add Product**
2. Find **Facebook Login** → Click **Set Up**
3. Go to **Facebook Login** → **Settings**
4. Add Valid OAuth Redirect URIs:
   ```
   https://buildkit-1695f.web.app/auth/facebook/callback
   ```
5. Click **Save Changes**

#### 4.3 Configure in Firebase

```bash
firebase functions:config:set facebook.app_id="1263833868842541"
firebase functions:config:set facebook.app_secret="6711e76ce39be55e3ff68ab755edd133"
```

**Replace with actual values from step 4.1**

---

### Step 5: Google Maps API Key

#### 5.1 Enable Google Maps APIs

1. In [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services** → **Library**
3. Search for and enable:
   - **Places API** (for Places search)
   - **Maps JavaScript API** (optional, for maps display)
   - **Geocoding API** (optional, for address conversion)

#### 5.2 Create API Key

1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **API Key**
3. Copy the API key
4. (Recommended) Click **Restrict Key**:
   - Application restrictions: **HTTP referrers**
   - Add: `https://buildkit-1695f.web.app/*`
   - API restrictions: **Restrict key**
     - Select: **Places API**, **Maps JavaScript API**, **Geocoding API**
   - Click **Save**

#### 5.3 Configure in Firebase

```bash
firebase functions:config:set google.maps_key="AIzaSyCy5ri97yn_kpHbY8dP1zMhfDQ6iUI_eqk"
```

**Replace with the API key from step 5.2**

---

### Step 6: Google OAuth (Optional - for Timeline Features)

#### 6.1 Create Google OAuth Client

1. In [Google Cloud Console](https://console.cloud.google.com/)
2. Go to **APIs & Services** → **Credentials**
3. Click **+ CREATE CREDENTIALS** → **OAuth client ID**
4. Application type: **Web application**
5. Name: **Smart Finder Google OAuth**
6. Authorized redirect URIs:
   ```
   https://buildkit-1695f.web.app/auth/google/callback
   ```
7. Click **Create**
8. **Copy Client ID and Client Secret**

#### 6.2 Configure in Firebase

```bash
firebase functions:config:set google.client_id="402603487375-8e80kh484j2kn84m8rh9d2navb1tkhmm.apps.googleusercontent.com"
firebase functions:config:set google.client_secret="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"
```

**Replace with actual values from step 6.1**

---

## ✅ Final Step: Deploy Configuration

After setting all credentials, deploy:

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# Verify all configs are set
firebase functions:config:get

# Deploy functions with new config
firebase deploy --only functions
```

---

## 🧪 Testing

### Test Each Platform:

1. **YouTube**:
   - Open: https://buildkit-1695f.web.app
   - Click "Connect YouTube"
   - Should open OAuth popup
   - After authorization, should connect successfully

2. **Instagram**:
   - Click "Connect Instagram"
   - Should open OAuth popup
   - After authorization, should connect successfully

3. **Facebook**:
   - Click "Connect Facebook"
   - Should open OAuth popup
   - After authorization, should connect successfully

4. **Search**:
   - Try: "Find travel videos" (tests YouTube API)
   - Try: "Show my Goa reels" (tests Instagram with OAuth)
   - Try: "Find nearby restaurants" (tests Google Maps API)

---

## 📋 Quick Reference - All Commands

Copy and paste these commands (replace with your actual values):

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# YouTube OAuth
firebase functions:config:set youtube.client_id="YOUR_YOUTUBE_CLIENT_ID"
firebase functions:config:set youtube.client_secret="YOUR_YOUTUBE_CLIENT_SECRET"

# YouTube Data API
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY"

# Instagram OAuth
firebase functions:config:set instagram.client_id="YOUR_INSTAGRAM_CLIENT_ID"
firebase functions:config:set instagram.client_secret="YOUR_INSTAGRAM_CLIENT_SECRET"

# Facebook OAuth
firebase functions:config:set facebook.app_id="YOUR_FACEBOOK_APP_ID"
firebase functions:config:set facebook.app_secret="YOUR_FACEBOOK_APP_SECRET"

# Google Maps API
firebase functions:config:set google.maps_key="YOUR_GOOGLE_MAPS_API_KEY"

# Google OAuth (Optional)
firebase functions:config:set google.client_id="YOUR_GOOGLE_CLIENT_ID"
firebase functions:config:set google.client_secret="YOUR_GOOGLE_CLIENT_SECRET"

# Deploy
firebase deploy --only functions
```

---

## 🔍 Verify Configuration

Run the status check script:

```bash
./SETUP_REQUIRED_KEYS.sh
```

All items should show ✅ CONFIGURED after setup.

---

## 🆘 Troubleshooting

### OAuth Redirect URI Mismatch
- Make sure redirect URIs in OAuth apps match exactly:
  - `https://buildkit-1695f.web.app/auth/youtube/callback`
  - `https://buildkit-1695f.web.app/auth/instagram/callback`
  - `https://buildkit-1695f.web.app/auth/facebook/callback`

### API Key Not Working
- Check if API is enabled in Google Cloud Console
- Verify API key restrictions allow your domain
- Check API quotas/limits

### OAuth Not Working
- Verify OAuth consent screen is configured
- Check if app is in "Development" mode (add test users)
- Verify redirect URIs match exactly

---

## 📚 Additional Resources

- **OAuth Setup Guide**: `OAUTH_SETUP_GUIDE.md`
- **YouTube API Setup**: `SETUP_YOUTUBE_API.md`
- **API Keys Status**: `API_KEYS_STATUS.md`

---

## ✅ Checklist

After completing all steps, verify:

- [ ] YouTube OAuth Client ID configured
- [ ] YouTube OAuth Client Secret configured
- [ ] YouTube Data API Key configured
- [ ] Instagram Client ID configured
- [ ] Instagram Client Secret configured
- [ ] Facebook App ID configured
- [ ] Facebook App Secret configured
- [ ] Google Maps API Key configured
- [ ] Google OAuth Client ID configured (optional)
- [ ] Google OAuth Client Secret configured (optional)
- [ ] All configs deployed
- [ ] Tested platform connections
- [ ] Tested search functionality

**Once all items are checked, your chatbot will work fully!** 🎉

---

## 🎯 Important: Developer Setup vs User Experience

### ⚠️ This Setup is for YOU (Developer) - One Time Only!

**After you complete this setup:**
- ✅ Your backend has all OAuth credentials
- ✅ Your backend has all API keys
- ✅ Users can connect their accounts via simple OAuth buttons
- ✅ **Users don't need to set up anything!**

### 👤 What Users Experience:

1. Open chatbot: https://buildkit-1695f.web.app
2. Click "Connect YouTube" → OAuth popup → Authorize → ✅ Done!
3. Click "Connect Instagram" → OAuth popup → Authorize → ✅ Done!
4. Start searching: "Find my saved videos" → Gets results!

**No technical setup, API keys, or OAuth credentials needed for users!**

**For full explanation, see:** [`DEVELOPER_VS_USER_SETUP.md`](DEVELOPER_VS_USER_SETUP.md)

