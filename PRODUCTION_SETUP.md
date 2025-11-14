# 🚀 Production Setup Guide - Make Chatbot Production Ready

## 🎯 Goal

Move chatbot to **production mode** so all users can use it without warnings or limitations.

---

## ✅ Step 1: Publish Google OAuth App for Verification

### Why This is Critical:
- Currently in "Testing" mode → Only test users can bypass warnings
- After verification → **ALL users** can use it seamlessly
- No manual test user addition needed

### Steps:

#### 1.1 Go to OAuth Consent Screen

1. Visit: https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f
2. Select project: **buildkit-1695f**

#### 1.2 Complete All Required Fields

**App Information:**
- ✅ App name: **Smart Finder AI Chatbot** (or your preferred name)
- ✅ User support email: **nikhilshingane@gmail.com**
- ✅ App logo: Upload a logo (optional but recommended)
- ✅ App domain: **buildkit-1695f.web.app**
- ✅ Developer contact information: **nikhilshingane@gmail.com**

**Scopes:**
Make sure these scopes are added:
- ✅ `https://www.googleapis.com/auth/youtube.readonly` (YouTube)
- ✅ `https://www.googleapis.com/auth/maps.timeline.readonly` (Timeline)
- ✅ `https://www.googleapis.com/auth/userinfo.email` (User info)
- ✅ `openid` (OpenID Connect)

**Test Users (Optional for Production):**
- You can remove test users after verification
- Or keep them for faster access during verification period

#### 1.3 Submit for Verification

1. Scroll to bottom
2. Click **"PUBLISH APP"** button
3. Review the warning
4. Click **"CONFIRM"**

**Verification Timeline:**
- ⏱️ Google reviews: **3-7 business days**
- 📧 You'll receive email updates
- ✅ Once approved, app is live for all users

---

## ✅ Step 2: Configure Facebook App for Production

### 2.1 Go to Facebook App Settings

1. Visit: https://developers.facebook.com/apps/
2. Select your app (App ID: **1263833868842541**)

### 2.2 Add App Domains

1. Go to **Settings** → **Basic**
2. Add **App Domains:**
   - `buildkit-1695f.web.app`
   - `buildkit-1695f.firebaseapp.com`
3. Click **"Save Changes"**

### 2.3 Configure OAuth Redirect URIs

1. Go to **Facebook Login** → **Settings**
2. Add **Valid OAuth Redirect URIs:**
   ```
   https://buildkit-1695f.web.app/auth/facebook/callback
   https://buildkit-1695f.firebaseapp.com/auth/facebook/callback
   ```
3. Click **"Save Changes"**

### 2.4 Submit for App Review (Optional)

For production, you may need to:
1. Go to **App Review** → **Permissions and Features**
2. Request permissions:
   - `user_posts`
   - `user_photos`
   - `user_videos`
3. Submit for review (if required)

---

## ✅ Step 3: Configure Instagram App for Production

### 3.1 Go to Instagram Basic Display Settings

1. In Facebook App, go to **Instagram** → **Basic Display**
2. Verify **Valid OAuth Redirect URIs:**
   ```
   https://buildkit-1695f.web.app/auth/instagram/callback
   ```

### 3.2 Add Test Users (For Testing)

1. In **Basic Display** settings
2. Add Instagram test users (for testing before production)

---

## ✅ Step 4: Verify All API Keys and Quotas

### 4.1 Check API Quotas

**Google Cloud Console:**
1. Go to: https://console.cloud.google.com/apis/dashboard?project=buildkit-1695f
2. Check quotas for:
   - YouTube Data API v3
   - Google Maps API (Places API)
   - OAuth 2.0 API

**Ensure quotas are sufficient for production traffic**

### 4.2 Set Up Billing Alerts (Important!)

1. Go to: https://console.cloud.google.com/billing
2. Set up billing alerts
3. Configure budget alerts to avoid unexpected charges

---

## ✅ Step 5: Firebase Production Configuration

### 5.1 Verify Firebase Functions

```bash
# Check current config
firebase functions:config:get

# Verify all keys are set:
# - youtube.client_id ✅
# - youtube.client_secret ✅
# - youtube.key ✅
# - instagram.client_id ✅
# - instagram.client_secret ✅
# - facebook.app_id ✅
# - facebook.app_secret ✅
# - google.maps_key ✅
# - google.client_id ✅
# - google.client_secret ✅
# - gemini.key ✅
# - openai.key ✅
```

### 5.2 Set Production Environment Variables

All environment variables should be set via Firebase Functions config (already done).

---

## ✅ Step 6: Security & Privacy

### 6.1 Privacy Policy

1. Create/update privacy policy
2. Add link in chatbot UI
3. Ensure compliance with GDPR, CCPA, etc.

### 6.2 Terms of Service

1. Create terms of service
2. Add link in chatbot UI

### 6.3 Data Handling

- ✅ User tokens stored securely in Firestore
- ✅ No sensitive data in frontend
- ✅ OAuth tokens encrypted

---

## ✅ Step 7: Monitoring & Logging

### 7.1 Enable Firebase Monitoring

1. Go to: https://console.firebase.google.com/project/buildkit-1695f/performance
2. Enable Performance Monitoring
3. Enable Crashlytics (optional)

### 7.2 Set Up Error Tracking

- Functions logs: https://console.firebase.google.com/project/buildkit-1695f/functions/logs
- Monitor for errors
- Set up alerts

---

## ✅ Step 8: Production Testing Checklist

### Before Going Live:

- [ ] Google OAuth app submitted for verification
- [ ] Facebook app domains configured
- [ ] Instagram redirect URIs verified
- [ ] All API keys configured
- [ ] API quotas checked
- [ ] Billing alerts set up
- [ ] Privacy policy added
- [ ] Terms of service added
- [ ] Error monitoring enabled
- [ ] Test all OAuth flows:
  - [ ] YouTube connection
  - [ ] Instagram connection
  - [ ] Facebook connection
  - [ ] Google connection
- [ ] Test search functionality:
  - [ ] Public content search
  - [ ] Saved content search
  - [ ] Nearby places search
  - [ ] Timeline search

---

## 🚀 Quick Start: Publish Google OAuth App NOW

**To start production testing immediately:**

1. **Go to:** https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f

2. **Complete these fields:**
   - App name: **Smart Finder AI Chatbot**
   - User support email: **nikhilshingane@gmail.com**
   - Developer contact: **nikhilshingane@gmail.com**
   - App domain: **buildkit-1695f.web.app**

3. **Verify scopes are added:**
   - YouTube readonly
   - Maps Timeline readonly
   - User info email
   - OpenID

4. **Click "PUBLISH APP"**

5. **Wait for verification (3-7 days)**

**During verification period:**
- App works for all users
- Users see "unverified" warning but can proceed
- After verification, warning disappears

---

## 📋 Production Readiness Status

Run this command to check:

```bash
./PRODUCTION_CHECK.sh
```

---

## 🎯 Next Steps

1. **Publish Google OAuth app** (most important)
2. **Configure Facebook/Instagram apps**
3. **Test all flows**
4. **Monitor for issues**
5. **Go live!**

---

## 📞 Support

If you encounter issues:
- Google OAuth: https://support.google.com/cloud/answer/10311615
- Facebook: https://developers.facebook.com/support/
- Firebase: https://firebase.google.com/support

**Let's make this production-ready! 🚀**

