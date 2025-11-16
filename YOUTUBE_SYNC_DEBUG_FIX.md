# 🔧 YouTube Sync Debug Fix - 0 Items Indexed Issue

## 🐛 Bug Found & Fixed

### Issue
The frontend was sending `accessToken: tokens.access_token` but the backend `/api/auth/save-tokens` endpoint was only looking for `token` parameter.

### Fix Applied ✅
- Updated `/api/auth/save-tokens` to accept both `token` and `accessToken` parameters
- Added detailed logging to track token saving
- Added logging to YouTube sync to track token usage

---

## 🔍 How to Debug

### Step 1: Reconnect YouTube
1. Go to: https://buildkit-1695f.web.app
2. Click "Connect YouTube" again
3. Complete OAuth flow
4. This will trigger token save with the fixed endpoint

### Step 2: Check Logs

After reconnecting, check Firebase logs:

```bash
firebase functions:log | grep -i "save-token\|youtube.*sync\|fetch.*start"
```

Look for:
- `[Save Tokens] Saving token for platform: youtube` ✅
- `[Save Tokens] ✅ Token saved successfully` ✅
- `[YouTube Sync] ========== FETCH START ==========` ✅
- `[YouTube Sync] Service.accessToken: present` ✅

### Step 3: Verify Token is Saved

Check if token is in Firestore:
- Go to Firebase Console → Firestore
- Check `users/{your-user-id}` document
- Look for `tokens.youtube` field
- Should contain the access token string

---

## 📋 What the Logs Will Show

### ✅ Success Flow:
```
[Save Tokens] Saving token for platform: youtube, user: sf-xxx, token length: 150
[Save Tokens] ✅ Token saved successfully for youtube
[Background Sync] Starting full sync for youtube for user sf-xxx
[Background Sync] Access token provided: true, length: 150
[YouTube Sync] ========== FETCH START ==========
[YouTube Sync] Service.accessToken: present
[YouTube Sync] Testing API access with token length: 150
[YouTube Sync] API access test successful. Channel: Your Channel Name
[YouTube Sync] Starting to fetch liked videos...
[YouTube Sync] ✅ Fetched 57 liked videos
[Background Sync] Fetched 57 items from youtube
[Indexing] Starting to index 57 items...
[Indexing] ✅ Complete: Indexed 57 items
```

### ❌ Failure Flow (Token Not Saved):
```
[Save Tokens] Missing required fields: { identifier: true, platform: 'youtube', oauthToken: false }
```

### ❌ Failure Flow (Token Expired):
```
[YouTube Sync] API access test FAILED: Invalid Credentials
[YouTube Sync] OAuth token expired or invalid. Please reconnect YouTube to get a fresh token.
```

---

## 🎯 Next Steps

1. **Reconnect YouTube** (to trigger token save with fixed endpoint)
2. **Check logs** using the commands above
3. **Share logs** if still showing 0 items

The fix is deployed. After reconnecting, the token should be saved correctly and sync should work!

---

## ✅ Status

- ✅ Bug fixed: Token save endpoint now accepts `accessToken` parameter
- ✅ Enhanced logging: Detailed logs for token save and sync
- ✅ Deployed: All changes are live

**Action Required:** Reconnect YouTube to save token with the fixed endpoint.

