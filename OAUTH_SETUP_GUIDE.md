# 🔐 OAuth Setup Guide - Fix Connection Errors

## ❌ Current Errors

1. **YouTube OAuth**: "Missing required parameter: client_id"
2. **Facebook OAuth**: "Invalid app ID"
3. **Chatbot**: "I couldn't find any results" (because platforms aren't connected)

---

## ✅ Solution: Configure OAuth Credentials

### Step 1: YouTube OAuth Setup

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/
   - Select project: **buildkit-1695f**

2. **Enable YouTube Data API:**
   - Go to **APIs & Services** → **Library**
   - Search for "YouTube Data API v3"
   - Click **Enable**

3. **Create OAuth 2.0 Credentials:**
   - Go to **APIs & Services** → **Credentials**
   - Click **Create Credentials** → **OAuth 2.0 Client ID**
   - If prompted, configure OAuth consent screen first:
     - User Type: **External**
     - App name: **Smart Finder AI**
     - User support email: Your email
     - Developer contact: Your email
     - Click **Save and Continue**
     - Scopes: Add `https://www.googleapis.com/auth/youtube.readonly`
     - Click **Save and Continue**
     - Test users: Add your email
     - Click **Save and Continue**

4. **Create OAuth Client:**
   - Application type: **Web application**
   - Name: **Smart Finder AI Web**
   - Authorized redirect URIs:
     ```
     https://buildkit-1695f.web.app/oauth-callback.html
     ```
   - Click **Create**
   - **Copy Client ID and Client Secret**

5. **Configure in Firebase:**
   ```bash
   firebase functions:config:set youtube.client_id="YOUR_CLIENT_ID"
   firebase functions:config:set youtube.client_secret="YOUR_CLIENT_SECRET"
   firebase deploy --only functions
   ```

---

### Step 2: Facebook OAuth Setup

1. **Go to Facebook Developers:**
   - Visit: https://developers.facebook.com/
   - Click **My Apps** → **Create App**

2. **Create App:**
   - App type: **Consumer** or **Business**
   - App name: **Smart Finder AI**
   - Contact email: Your email
   - Click **Create App**

3. **Add Products:**
   - Add **Facebook Login**
   - Add **Instagram Graph API** (if needed)

4. **Configure OAuth Settings:**
   - Go to **Facebook Login** → **Settings**
   - Valid OAuth Redirect URIs:
     ```
     https://buildkit-1695f.web.app/oauth-callback.html
     ```
   - Click **Save Changes**

5. **Get App ID and Secret:**
   - Go to **Settings** → **Basic**
   - **Copy App ID**
   - **Copy App Secret** (click Show)

6. **Configure in Firebase:**
   ```bash
   firebase functions:config:set facebook.app_id="YOUR_APP_ID"
   firebase functions:config:set facebook.app_secret="YOUR_APP_SECRET"
   firebase deploy --only functions
   ```

---

### Step 3: Instagram OAuth Setup

1. **In Facebook Developers:**
   - Same app as Facebook
   - Go to **Instagram Graph API** product
   - Get **Instagram App ID** and **Instagram App Secret**

2. **Configure in Firebase:**
   ```bash
   firebase functions:config:set instagram.client_id="YOUR_INSTAGRAM_APP_ID"
   firebase functions:config:set instagram.client_secret="YOUR_INSTAGRAM_APP_SECRET"
   firebase deploy --only functions
   ```

---

## 🚀 Quick Setup Commands

After getting all credentials, run:

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot

# YouTube
firebase functions:config:set youtube.client_id="YOUR_YOUTUBE_CLIENT_ID"
firebase functions:config:set youtube.client_secret="YOUR_YOUTUBE_CLIENT_SECRET"

# Facebook
firebase functions:config:set facebook.app_id="YOUR_FACEBOOK_APP_ID"
firebase functions:config:set facebook.app_secret="YOUR_FACEBOOK_APP_SECRET"

# Instagram
firebase functions:config:set instagram.client_id="YOUR_INSTAGRAM_APP_ID"
firebase functions:config:set instagram.client_secret="YOUR_INSTAGRAM_APP_SECRET"

# Deploy
firebase deploy --only functions
```

---

## ✅ Verify Configuration

Check if credentials are set:

```bash
firebase functions:config:get
```

You should see:
- `youtube.client_id`
- `youtube.client_secret`
- `facebook.app_id`
- `facebook.app_secret`
- `instagram.client_id`
- `instagram.client_secret`

---

## 🧪 Test Connection

1. **Open chatbot**: https://buildkit-1695f.web.app
2. **Click**: "Connect your accounts"
3. **Enter**: Email/mobile
4. **Click**: "Connect YouTube" or "Connect Facebook"
5. **Should redirect**: To OAuth page (not error page)
6. **Authorize**: Grant permissions
7. **Should redirect back**: Successfully connected

---

## 📝 Important Notes

1. **OAuth Consent Screen**: Must be configured for Google
2. **Redirect URIs**: Must match exactly (including https://)
3. **App Status**: Facebook apps start in "Development" mode
4. **Test Users**: Add test users in Google OAuth consent screen
5. **Deploy**: Always deploy functions after setting config

---

## 🔧 Troubleshooting

### Error: "Missing client_id"
- **Fix**: Set `youtube.client_id` in Firebase config
- **Verify**: `firebase functions:config:get`

### Error: "Invalid app ID"
- **Fix**: Set `facebook.app_id` in Firebase config
- **Verify**: App ID is correct in Facebook Developers

### Error: "Redirect URI mismatch"
- **Fix**: Ensure redirect URI in OAuth config matches:
  ```
  https://buildkit-1695f.web.app/oauth-callback.html
  ```

### Still not working?
- Check Firebase Functions logs:
  ```bash
  firebase functions:log
  ```
- Verify credentials are set:
  ```bash
  firebase functions:config:get
  ```

---

## 🎯 After Setup

Once OAuth is configured:
1. ✅ Users can connect platforms
2. ✅ Auto-sync will fetch all saved content
3. ✅ Chatbot will find results from indexed content
4. ✅ Everything will work seamlessly!

