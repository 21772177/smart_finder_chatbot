# YouTube API Setup - Required for Public Video Search

## ⚠️ Current Issue

The chatbot is returning "no results" because the **YouTube Data API key is not configured**.

## Why YouTube API Key is Needed

Even for **public video search** (not saved content), YouTube requires an API key:
- ✅ **Public search** → Requires YouTube Data API key
- 🔐 **Saved content search** → Requires OAuth + API key

## Quick Setup

### Step 1: Get YouTube Data API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project: **buildkit-1695f**
3. Go to **APIs & Services** → **Library**
4. Search for "YouTube Data API v3"
5. Click **Enable**
6. Go to **APIs & Services** → **Credentials**
7. Click **Create Credentials** → **API Key**
8. Copy the API key

### Step 2: Configure the API Key

```bash
cd /home/nikhilesh/Android/Sdk/smart_finder_chatbot
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY_HERE"
firebase deploy --only functions
```

### Step 3: Test

After deployment, try:
```
"Find Goa travel videos"
```

You should now see public YouTube videos!

## What Works After Setup

### ✅ Without OAuth (Public Search)
- Search public YouTube videos
- Get video information
- View thumbnails and descriptions
- Open videos in YouTube

### 🔐 With OAuth (Saved Content)
- Search YOUR saved videos
- Search YOUR playlists
- Search YOUR liked videos

## Current Status

**Without YouTube API Key:**
- ❌ Cannot search YouTube (public or saved)
- ✅ Can still use other features (nearby places, etc.)

**With YouTube API Key (No OAuth):**
- ✅ Can search public YouTube videos
- ❌ Cannot search your saved videos

**With YouTube API Key + OAuth:**
- ✅ Can search public YouTube videos
- ✅ Can search your saved videos

## Alternative: Use Mock Data (Development)

For testing without API key, you can modify the code to return mock data, but for production, you need the API key.

---

**After setting up the YouTube API key, the chatbot will work for public video searches!**

