# 🧪 Testing URLs - Smart Finder Chatbot

## 🌐 Live Chatbot URL

**Primary URL:**
```
https://buildkit-1695f.web.app
```

**Alternative URL:**
```
https://buildkit-1695f.firebaseapp.com
```

---

## 🔗 API Endpoint

**Functions URL:**
```
https://us-central1-buildkit-1695f.cloudfunctions.net/api
```

---

## 📱 How to Test

### 1. Open the Chatbot

Visit: **https://buildkit-1695f.web.app**

### 2. Test OAuth Connections

1. **Connect YouTube:**
   - Click "Connect YouTube" button
   - OAuth popup should open
   - Log in and authorize
   - Should show "✅ YouTube connected successfully!"

2. **Connect Instagram:**
   - Click "Connect Instagram" button
   - OAuth popup should open
   - Log in and authorize
   - Should show "✅ Instagram connected successfully!"

3. **Connect Facebook:**
   - Click "Connect Facebook" button
   - OAuth popup should open
   - Log in and authorize
   - Should show "✅ Facebook connected successfully!"

### 3. Test Search Functionality

#### Public Search (No Auth Required):
- **Query:** "Find travel videos about Paris"
- **Expected:** Returns YouTube public videos

#### Saved Content Search (Auth Required):
- **Query:** "Show my saved travel videos"
- **Expected:** Searches connected accounts and returns saved content

#### Nearby Places Search:
- **Query:** "Find nearby restaurants"
- **Expected:** Returns Google Places results

#### Timeline Search (Google Auth Required):
- **Query:** "Where did I visit last month?"
- **Expected:** Returns Google Timeline results

---

## ✅ What's Configured

- ✅ YouTube OAuth (Client ID + Secret)
- ✅ YouTube Data API Key
- ✅ Instagram OAuth (Client ID + Secret)
- ✅ Facebook OAuth (App ID + Secret)
- ✅ Google Maps API Key
- ✅ Google OAuth (Client ID + Secret)
- ✅ Gemini API Key
- ✅ OpenAI API Key

---

## 🎯 Quick Test Checklist

- [ ] Open chatbot URL
- [ ] Test YouTube connection
- [ ] Test Instagram connection
- [ ] Test Facebook connection
- [ ] Test public video search
- [ ] Test saved content search (after connecting accounts)
- [ ] Test nearby places search
- [ ] Test timeline search (after connecting Google)

---

## 📊 Project Console

**Firebase Console:**
```
https://console.firebase.google.com/project/buildkit-1695f
```

**Functions Logs:**
```
https://console.firebase.google.com/project/buildkit-1695f/functions/logs
```

---

## 🚀 Status

**Deployment:** ✅ Complete
**Functions:** ✅ Deployed
**Hosting:** ✅ Live
**All API Keys:** ✅ Configured

**Ready for testing!** 🎉

