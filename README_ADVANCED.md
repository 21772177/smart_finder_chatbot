# Smart Finder AI Chatbot - Advanced Multi-Platform Search

## 🚀 What's New

This chatbot now includes **advanced AI capabilities** to search saved content across multiple platforms:

### ✨ Key Features

1. **LLM-Powered Query Understanding**
   - Uses OpenAI GPT-4 for intelligent intent classification
   - Understands natural language queries
   - Extracts platforms and keywords automatically

2. **RAG (Retrieval Augmented Generation)**
   - Semantic search using embeddings
   - Firestore as vector store
   - Hybrid search (semantic + keyword matching)

3. **Agentic AI Router**
   - Intelligently routes queries to appropriate platforms
   - Searches multiple platforms in parallel
   - Combines and deduplicates results

4. **Multi-Platform Support**
   - ✅ YouTube (saved videos, playlists)
   - ✅ Instagram (saved reels, posts)
   - ✅ Facebook (saved posts, videos)
   - 🔄 More platforms coming soon

5. **Content Indexing**
   - Automatically indexes found content
   - Enables fast semantic search
   - Caches for offline access

## 📋 Quick Start

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Set API Keys

```bash
# Required: OpenAI API Key
firebase functions:config:set openai.key="sk-..."

# Optional: YouTube API Key (for public search)
firebase functions:config:set youtube.key="AIza..."

firebase deploy --only functions
```

### 3. Deploy

```bash
firebase deploy
```

### 4. Connect User Accounts

Users need to authenticate with platforms:

```javascript
// Save OAuth tokens
POST /api/auth/save-tokens
{
  "userId": "user123",
  "platform": "youtube",
  "token": "oauth_token"
}
```

### 5. Search!

Users can now search:
- "Find Goa travel reels I saved"
- "Show me cooking videos from YouTube"
- "Find that Instagram post about beaches"
- "Search my saved Facebook videos"

## 🏗️ Architecture

```
User Query
    ↓
OpenAI GPT-4 (Intent Parser)
    ↓
Agentic Router
    ↓
┌─────────────────────────────┐
│ Parallel Search:            │
│ • RAG (Firestore Index)     │
│ • YouTube API               │
│ • Instagram API             │
│ • Facebook API              │
└─────────────────────────────┘
    ↓
Aggregate Results
    ↓
OpenAI GPT-4 (Response Gen)
    ↓
Return to User
```

## 📚 Documentation

- **IMPLEMENTATION_GUIDE.md** - Detailed technical guide
- **QUICKSTART.md** - Quick setup instructions
- **FIREBASE_SETUP.md** - Firebase configuration

## 🔧 Technologies Used

- **OpenAI GPT-4** - LLM for query understanding
- **OpenAI Embeddings** - Vector embeddings for RAG
- **Firestore** - Vector store and database
- **YouTube Data API** - YouTube integration
- **Instagram Graph API** - Instagram integration
- **Facebook Graph API** - Facebook integration
- **Firebase Functions** - Serverless backend
- **Express** - API framework

## 💡 Example Queries

- "Find Goa travel reels I saved last month"
- "Show me cooking videos from YouTube"
- "Search my saved Instagram posts about beaches"
- "Find that Facebook video about travel"
- "What reels did I save about food?"

## 🎯 How It Works

1. **User asks**: "Find Goa travel reels"
2. **LLM analyzes**: Intent = saved_content, Platform = instagram, Keywords = ["goa", "travel", "reel"]
3. **Router searches**:
   - RAG index (Firestore) for indexed content
   - Instagram API for live saved content
4. **Results combined** and deduplicated
5. **LLM generates** natural language response
6. **User sees** formatted results with thumbnails and links

## 📊 Performance

- **Query Time**: ~2-5 seconds (depending on platforms)
- **Accuracy**: High (semantic + keyword matching)
- **Scalability**: Handles thousands of indexed items
- **Cost**: ~$0.01-0.05 per query (with OpenAI)

## 🔐 Security

- OAuth tokens stored securely in Firestore
- User-specific content indexing
- Firestore security rules enforce access control
- No content stored without user permission

## 🚧 Limitations

1. Requires OAuth tokens for saved content access
2. Instagram API has limited access
3. Rate limits apply to platform APIs
4. OpenAI API costs apply

## 🔮 Future Enhancements

- [ ] More platforms (TikTok, Twitter/X, Pinterest)
- [ ] Advanced vector database (Pinecone, Weaviate)
- [ ] Real-time content sync
- [ ] Content recommendations
- [ ] Voice search
- [ ] Mobile app

## 📞 Support

For issues or questions, check:
- IMPLEMENTATION_GUIDE.md for technical details
- Firebase Console logs for errors
- Platform API documentation for OAuth setup

---

**Built with ❤️ using Firebase, OpenAI, and modern AI technologies**

