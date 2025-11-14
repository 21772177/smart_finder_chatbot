# 🔍 Debug Chatbot Issues - Step-by-Step Guide

## Problem: "I couldn't find any results for your query"

**Even though YouTube is connected, queries return no results.**

---

## 🔍 Step 1: Check Logs

### View Firebase Functions Logs

**Command:**
```bash
firebase functions:log --only api
```

**Or in Firebase Console:**
1. Go to: https://console.firebase.google.com/project/buildkit-1695f/functions/logs
2. Look for logs with `[Query Debug]` prefix

**What to look for:**
- `[Query Debug] User: ...` - Shows user identifier
- `[Query Debug] Intent: ...` - Shows detected intent
- `[Query Debug] User tokens - YouTube: true/false` - Shows if tokens are available
- `[Query Debug] Search completed - Found X results` - Shows search results

---

## 🔍 Step 2: Check Sync Status

### Use Debug Endpoint

**URL:**
```
https://buildkit-1695f.web.app/api/debug/status?token=YOUR_DEVICE_TOKEN
```

**Or from browser console:**
```javascript
// Get device token from localStorage
const token = localStorage.getItem('sf_device_token');
fetch(`/api/debug/status?token=${token}`)
  .then(r => r.json())
  .then(console.log);
```

**What to check:**
- `tokens.youtube.connected` - Should be `true`
- `contentIndexed` - Should be > 0 if sync completed
- `hasContent` - Should be `true` if content is indexed

---

## 🔍 Step 3: Check if Sync Ran

### Check Background Sync

**From browser console:**
```javascript
// Check if sync was triggered
const token = localStorage.getItem('sf_device_token');
fetch('/api/sync-all', {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify({token: token})
})
.then(r => r.json())
.then(console.log);
```

**Expected response:**
```json
{
  "success": true,
  "message": "Synced X items from Y platform(s)",
  "totalFetched": 10,
  "totalIndexed": 10,
  "results": [...]
}
```

---

## 🔍 Step 4: Check Intent Parsing

### Test Intent Detection

**The issue might be intent parsing. Check logs for:**
- `[Query Debug] Intent: ...` - Should be `saved_content`, `reel_search`, or `video_search`
- If intent is `general`, that's the problem!

**Fix:** The code now includes fallback pattern matching, so queries with "reel", "saved", "liked" should work even if intent is wrong.

---

## 🔍 Step 5: Check Content Index

### Verify Content is Indexed in Firestore

**From Firebase Console:**
1. Go to: https://console.firebase.google.com/project/buildkit-1695f/firestore
2. Navigate to `content_index` collection
3. Filter by `userId` = your device token
4. Check if documents exist

**If no documents:**
- Sync didn't run or failed
- Check sync logs for errors

---

## 🔍 Step 6: Manual Sync Test

### Force Sync Manually

**From browser console:**
```javascript
const token = localStorage.getItem('sf_device_token');
const ytToken = JSON.parse(localStorage.getItem('sf_youtube_tokens'));

// Sync YouTube manually
fetch('/api/sync', {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify({
    token: token,
    platform: 'youtube',
    token: ytToken?.access_token
  })
})
.then(r => r.json())
.then(console.log);
```

**Expected:**
```json
{
  "success": true,
  "platform": "youtube",
  "itemsFetched": 10,
  "itemsIndexed": 10,
  "message": "Synced 10 items from youtube"
}
```

---

## 🐛 Common Issues & Fixes

### Issue 1: Intent is "general" instead of "saved_content"

**Symptom:** Logs show `Intent: general`

**Fix:** ✅ Already fixed - Added pattern matching fallback

**Test:** Query "Show goa reels" should now work even if intent is wrong

---

### Issue 2: No tokens found

**Symptom:** Logs show `User tokens - YouTube: false`

**Fix:**
1. Reconnect YouTube
2. Check localStorage: `localStorage.getItem('sf_youtube_tokens')`
3. Check if token is saved to backend

---

### Issue 3: Sync didn't run

**Symptom:** `contentIndexed: 0` in debug status

**Fix:**
1. Manually trigger sync (see Step 6)
2. Check sync logs for errors
3. Verify OAuth token is valid

---

### Issue 4: Content indexed but not found

**Symptom:** `contentIndexed > 0` but queries return no results

**Fix:**
1. Check RAG search logs
2. Verify query keywords match content
3. Check embedding generation

---

## 📋 Quick Diagnostic Checklist

**Run these checks:**

- [ ] **Logs show query received?** → Check `[Query Debug]` logs
- [ ] **Intent detected correctly?** → Should be `saved_content` or similar
- [ ] **Tokens available?** → Check `User tokens - YouTube: true`
- [ ] **Sync completed?** → Check `contentIndexed > 0`
- [ ] **Content in Firestore?** → Check `content_index` collection
- [ ] **Search ran?** → Check `[Query Debug] Search completed`

---

## 🚀 Quick Fix: Force Full Sync

**If nothing works, force a full sync:**

```javascript
// In browser console
const token = localStorage.getItem('sf_device_token');
fetch('/api/sync-all', {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify({token: token})
})
.then(r => r.json())
.then(data => {
  console.log('Sync result:', data);
  if (data.success) {
    console.log(`✅ Synced ${data.totalIndexed} items`);
    // Try query again
  } else {
    console.error('❌ Sync failed:', data);
  }
});
```

---

## 📞 Report Issues

**If still not working, share:**
1. Logs from `[Query Debug]` entries
2. Debug status response
3. Sync result
4. Query that failed

**I'll help fix it!**

