# ⚡ OAuth Consent Screen - Quick Reference Card

## 🎯 Quick Values to Copy-Paste

```
App name: Smart Finder AI Chatbot
User support email: nikhilshingane@gmail.com
Application home page: https://buildkit-1695f.web.app
Privacy policy link: https://buildkit-1695f.web.app/privacy
Authorized domain: buildkit-1695f.web.app
Developer contact: nikhilshingane@gmail.com
```

---

## 🔗 Direct Link

```
https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f
```

---

## 📋 Page-by-Page Checklist

### Page 1: App Information

**Fill these fields (in order):**

1. **App name:** `Smart Finder AI Chatbot`
2. **User support email:** `nikhilshingane@gmail.com`
3. **App logo:** (Skip - optional)
4. **Application home page:** `https://buildkit-1695f.web.app`
5. **Privacy policy link:** `https://buildkit-1695f.web.app/privacy`
6. **Terms of service:** (Skip - optional)
7. **Authorized domains:** Click "+" → Add `buildkit-1695f.web.app`
8. **Developer contact:** `nikhilshingane@gmail.com`

**Then click:** `SAVE AND CONTINUE`

---

### Page 2: Scopes

**Verify these scopes exist:**

- ✅ `https://www.googleapis.com/auth/youtube.readonly`
- ✅ `https://www.googleapis.com/auth/maps.timeline.readonly`
- ✅ `https://www.googleapis.com/auth/userinfo.email`
- ✅ `openid`

**If missing:** Click "+ ADD OR REMOVE SCOPES" → Add → UPDATE

**Then click:** `SAVE AND CONTINUE`

---

### Page 3: Test Users

**Options:**
- Leave empty (recommended for production)
- OR add: `nikhilshingane@gmail.com`

**Then click:** `SAVE AND CONTINUE`

---

### Page 4: Summary

**Review everything**

**Then click:** `BACK TO DASHBOARD`

---

## 🚀 Publish

1. Find **"PUBLISH APP"** button (top of page)
2. Click it
3. Click **"CONFIRM"** in warning dialog
4. ✅ Done!

---

## ⚠️ Common Mistakes to Avoid

❌ **Don't include `https://` in authorized domains**
✅ **Correct:** `buildkit-1695f.web.app`

❌ **Don't include trailing slash in URLs**
✅ **Correct:** `https://buildkit-1695f.web.app`

❌ **Don't use different email addresses**
✅ **Use:** `nikhilshingane@gmail.com` consistently

---

## 📖 Need More Details?

**See:** `OAUTH_CONSENT_SCREEN_DETAILED.md` - Complete step-by-step guide

---

## ✅ Final Step

After publishing:
- ✅ App is live
- ⚠️ May show "unverified" warning (normal)
- ✅ Users can proceed
- ✅ After 3-7 days, warning disappears

**Start testing:** https://buildkit-1695f.web.app

