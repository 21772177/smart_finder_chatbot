# Smart Finder AI Chatbot

An intelligent multi-platform content search chatbot powered by LLM, RAG, and Agentic AI.

## 🚀 Features

- **Multi-Platform Search**: Search saved content across YouTube, Instagram, Facebook
- **LLM-Powered**: Uses Gemini AI (with OpenAI fallback) for intelligent query understanding
- **RAG System**: Semantic search on indexed content for instant results
- **Agentic Router**: Intelligently routes queries to appropriate platforms
- **Auto-Sync**: Automatically indexes your saved content in the background
- **OAuth Integration**: Secure platform connections with direct OAuth flows
- **Places Search**: Find nearby restaurants, cafes, and more
- **Timeline Recall**: Remember past visits and locations

## 📋 Prerequisites

- Node.js 20+
- Firebase account
- API keys (see setup below)

## ⚙️ Required API Keys

**All API keys are mandatory for full functionality.** See `env.example` for complete list.

### Essential (Minimum Required)

1. **LLM API Key** (Choose one):
   - `GEMINI_API_KEY` - Recommended (cheaper, better Google integration)
   - `OPENAI_API_KEY` - Alternative/fallback

2. **YouTube API Key**:
   - `YT_API_KEY` or `YOUTUBE_API_KEY` - For public video search

3. **OAuth Credentials** (For platform connections):
   - `YT_OAUTH_CLIENT_ID` & `YT_OAUTH_CLIENT_SECRET` - YouTube OAuth
   - `INSTAGRAM_CLIENT_ID` & `INSTAGRAM_CLIENT_SECRET` - Instagram OAuth
   - `FACEBOOK_APP_ID` & `FACEBOOK_APP_SECRET` - Facebook OAuth

### Optional (For Enhanced Features)

- `GOOGLE_MAPS_KEY` - For Places search
- `GOOGLE_OAUTH_CLIENT_ID` & `GOOGLE_OAUTH_CLIENT_SECRET` - For Timeline features
- `OAUTH_REDIRECT_BASE` - Custom OAuth redirect URL

## 🛠️ Quick Setup

### 1. Clone Repository

```bash
git clone https://github.com/21772177/smart_finder_chatbot.git
cd smart_finder_chatbot
```

### 2. Install Dependencies

```bash
cd functions
npm install
cd ..
```

### 3. Configure API Keys

**Option A: Using Firebase Functions Config (Recommended)**

```bash
# LLM (Required - at least one)
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
# OR
firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"

# YouTube (Required)
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY"

# Google Maps (Optional)
firebase functions:config:set google.maps_key="YOUR_MAPS_API_KEY"

# OAuth Credentials (Required for platform connections)
firebase functions:config:set youtube.client_id="YOUR_CLIENT_ID"
firebase functions:config:set youtube.client_secret="YOUR_CLIENT_SECRET"
firebase functions:config:set instagram.client_id="YOUR_CLIENT_ID"
firebase functions:config:set instagram.client_secret="YOUR_CLIENT_SECRET"
firebase functions:config:set facebook.app_id="YOUR_APP_ID"
firebase functions:config:set facebook.app_secret="YOUR_APP_SECRET"

# Deploy config
firebase deploy --only functions
```

**Option B: Using .env file (Local Development)**

```bash
cp env.example .env
# Edit .env and add your API keys
```

### 4. Deploy

```bash
firebase deploy --only functions,hosting
```

## 📚 Documentation

- **`env.example`** - Complete list of all required API keys
- **`OAUTH_SETUP_GUIDE.md`** - Detailed OAuth setup instructions
- **`GEMINI_SETUP.md`** - Gemini API setup and comparison
- **`SETUP_YOUTUBE_API.md`** - YouTube API setup guide
- **`QUICKSTART.md`** - Quick start guide
- **`COMPLETE_USER_GUIDE.md`** - Complete user guide

## 🔑 Getting API Keys

### Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create API key
3. Copy and set in config

### YouTube API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable "YouTube Data API v3"
3. Create API key
4. Copy and set in config

### OAuth Credentials
See `OAUTH_SETUP_GUIDE.md` for detailed instructions on getting OAuth credentials for each platform.

## 🌐 Live Demo

**URL**: https://buildkit-1695f.web.app

## 📖 Usage

1. Open the chatbot URL
2. Connect your social media accounts (YouTube, Instagram, Facebook)
3. Ask questions like:
   - "Show my Goa reels"
   - "Find travel videos I saved"
   - "What restaurants are nearby?"
   - "Show me my liked YouTube videos"

## 🏗️ Architecture

```
User Query
    ↓
LLM Intent Parser (Gemini/OpenAI)
    ↓
Agentic Router (decides platforms)
    ↓
Parallel Search:
  - RAG (Firestore indexed cache)
  - YouTube API (live)
  - Instagram API (live)
  - Facebook API (live)
    ↓
Aggregate & Deduplicate
    ↓
LLM Response Generation
    ↓
Return Results
```

## 🔄 Updating GitHub

```bash
./update_github.sh "Your commit message"
```

## 📝 License

[Your License Here]

## 🤝 Contributing

[Contributing Guidelines]

---

**Note**: All API keys listed in `env.example` are **mandatory** for the chatbot to work with platforms. Make sure to configure all required keys before deployment.
