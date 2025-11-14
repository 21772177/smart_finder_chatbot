# 🔧 Fix Google OAuth "App Not Verified" Error

## Problem

When users try to connect YouTube or Google accounts, they see:
> **"Google hasn't verified this app"**

This happens because your OAuth app is in **Development/Testing mode** and needs test users added.

---

## ✅ Solution: Add Test Users

### Step 1: Go to Google Cloud Console

1. Visit: [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **buildkit-1695f**
3. Go to **APIs & Services** → **OAuth consent screen**

### Step 2: Add Test Users

1. Scroll down to **"Test users"** section
2. Click **"+ ADD USERS"**
3. Add email addresses of users who will test the app:
   - Your email: `nikhilshingane@gmail.com`
   - Any other test users' emails
4. Click **"ADD"**

### Step 3: Save Changes

- Click **"SAVE"** at the bottom

---

## ✅ Alternative: Publish App (For Production)

If you want to allow all users without adding them individually:

### Step 1: Complete OAuth Consent Screen

1. Go to **OAuth consent screen**
2. Fill in all required fields:
   - App name
   - User support email
   - Developer contact email
   - App logo (optional)
   - App domain (optional)
   - Authorized domains

### Step 2: Add Scopes

Make sure these scopes are added:
- `https://www.googleapis.com/auth/youtube.readonly` (for YouTube)
- `https://www.googleapis.com/auth/maps.timeline.readonly` (for Timeline)
- `https://www.googleapis.com/auth/userinfo.email` (for user info)
- `openid` (for OpenID Connect)

### Step 3: Submit for Verification

1. Click **"PUBLISH APP"** button
2. Review the warning
3. Click **"CONFIRM"**

**Note:** Verification can take several days. For testing, adding test users is faster.

---

## 🎯 Quick Fix (Recommended for Testing)

**For immediate testing, just add test users:**

1. Go to: https://console.cloud.google.com/apis/credentials/consent
2. Select project: **buildkit-1695f**
3. Scroll to **"Test users"**
4. Click **"+ ADD USERS"**
5. Add: `nikhilshingane@gmail.com` (and any other test emails)
6. Click **"SAVE"**

**After this, the "App not verified" warning will still appear, but users can click "Advanced" → "Go to [App Name] (unsafe)" to proceed.**

---

## 📝 For Production (Later)

When ready for production:

1. Complete all OAuth consent screen fields
2. Submit app for verification
3. Wait for Google's approval (3-7 days typically)
4. Once verified, all users can use the app without warnings

---

## ✅ Status After Fix

- ✅ Test users can connect YouTube/Google accounts
- ✅ They'll see warning but can proceed via "Advanced" → "Go to app (unsafe)"
- ✅ OAuth flow will work correctly
- ✅ For production, submit for verification

---

## 🔗 Direct Links

- **OAuth Consent Screen:** https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f
- **Credentials:** https://console.cloud.google.com/apis/credentials?project=buildkit-1695f

