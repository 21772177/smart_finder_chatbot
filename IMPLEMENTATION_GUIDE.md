# Advanced Implementation Guide - Multi-Platform Search with RAG & Agentic AI

## Overview

This chatbot now includes:
- **LLM Integration** (OpenAI GPT-4) for intelligent query understanding
- **RAG System** (Retrieval Augmented Generation) using Firestore as vector store
- **Agentic AI Router** for intelligent multi-platform routing
- **Multi-Platform Support**: YouTube, Instagram, Facebook
- **Content Indexing** with embeddings for semantic search

## Architecture

```
User Query
    ↓
LLM Intent Parser (OpenAI GPT-4)
    ↓
Agentic Router (decides platforms)
    ↓
┌─────────────────────────────────┐
│  Parallel Search:                │
│  - RAG (Firestore indexed)      │
│  - YouTube API (live)           │
│  - Instagram API (live)         │
│  - Facebook API (live)          │
└─────────────────────────────────┘
    ↓
Aggregate & Deduplicate
    ↓
LLM Response Generation
    ↓
Return Results
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure API Keys

**Recommended: Use Gemini (96% cheaper, better Google integration)**

Set environment variables in Firebase Functions:

```bash
# Set Gemini API Key (RECOMMENDED - cheaper, better Google integration)
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"

# OR Set OpenAI API Key (alternative/fallback)
firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"

# Set YouTube API Key (optional, for public search)
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY"

# Deploy config
firebase deploy --only functions
```

**Get Gemini API Key**: [Google AI Studio](https://makersuite.google.com/app/apikey)

Or use environment variables:
```bash
export GEMINI_API_KEY="your-key"  # Recommended
# OR
export OPENAI_API_KEY="your-key"  # Alternative
export YOUTUBE_API_KEY="your-key"
```

**Note**: The system will use Gemini if available, otherwise falls back to OpenAI. See `GEMINI_SETUP.md` for detailed comparison.

### 3. OAuth Setup for Platforms

#### YouTube OAuth
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create OAuth 2.0 credentials
3. Add authorized redirect URIs
4. Users need to authorize via OAuth flow

#### Instagram OAuth
1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create an app
3. Add Instagram Graph API product
4. Get access token with `instagram_basic`, `pages_read_engagement` permissions

#### Facebook OAuth
1. Same as Instagram (Facebook Developers)
2. Get access token with `user_posts`, `user_photos` permissions

### 4. Save User Tokens

Users need to authenticate and save tokens:

```javascript
// Frontend: After OAuth flow
await fetch('/api/auth/save-tokens', {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify({
    userId: 'user123',
    platform: 'youtube',
    token: 'oauth_token_here'
  })
});
```

### 5. Sync Content (Optional)

To pre-index user's saved content:

```javascript
await fetch('/api/sync', {
  method: 'POST',
  headers: {'Content-Type':'application/json'},
  body: JSON.stringify({
    userId: 'user123',
    platform: 'youtube',
    token: 'oauth_token'
  })
});
```

## How It Works

### 1. Query Processing Flow

1. **User sends query**: "Find Goa travel reels I saved last month"

2. **LLM Intent Parser**:
   - Uses GPT-4 to classify intent
   - Extracts platforms: ["instagram"]
   - Extracts keywords: ["goa", "travel", "reel"]

3. **Agentic Router**:
   - Decides to search Instagram (explicit) + YouTube (fallback)
   - Searches RAG index (Firestore) for indexed content
   - Searches live APIs in parallel

4. **RAG Search**:
   - Generates query embedding
   - Searches Firestore `content_index` collection
   - Uses cosine similarity for ranking
   - Combines with keyword matching

5. **Result Aggregation**:
   - Deduplicates by URL/ID
   - Prioritizes RAG results (indexed)
   - Adds live API results

6. **LLM Response**:
   - GPT-4 generates natural language response
   - Formats results nicely

### 2. RAG System Details

**Content Indexing**:
- When content is found, it's automatically indexed
- Embeddings generated using `text-embedding-3-small`
- Stored in Firestore `content_index` collection
- Includes: title, description, platform, URL, timestamp

**Search Process**:
- Query → Embedding
- Cosine similarity with indexed embeddings
- Keyword matching for fast filtering
- Hybrid search (semantic + keyword)

### 3. Agentic Router

The router intelligently:
- Detects which platforms to search
- Searches multiple platforms in parallel
- Combines RAG (indexed) + API (live) results
- Deduplicates and ranks results

## API Endpoints

### POST `/api/query`
Main search endpoint

**Request**:
```json
{
  "query": "Find Goa travel reels",
  "token": "device_token",
  "userId": "user123",
  "location": {"lat": 12.9716, "lng": 77.5946}
}
```

**Response**:
```json
{
  "session_id": "sess-123",
  "response": "I found 5 travel reels about Goa...",
  "results": [...],
  "intent": "saved_content",
  "platforms_searched": ["instagram", "youtube"]
}
```

### POST `/api/sync`
Sync content from platform to Firestore

**Request**:
```json
{
  "userId": "user123",
  "platform": "youtube",
  "token": "oauth_token"
}
```

### POST `/api/auth/save-tokens`
Save OAuth tokens for user

**Request**:
```json
{
  "userId": "user123",
  "platform": "youtube",
  "token": "oauth_token"
}
```

## Firestore Structure

### `content_index` Collection
```javascript
{
  userId: "user123",
  platform: "youtube",
  content: {
    id: "video_id",
    title: "Video Title",
    url: "https://...",
    thumbnail: "https://...",
    ...
  },
  text: "Video Title Description...",
  embedding: [0.123, 0.456, ...], // 1536 dimensions
  keywords: ["goa", "travel", "beach"],
  timestamp: Timestamp,
  indexed: true
}
```

### `sessions` Collection
```javascript
{
  session_id: "sess-123",
  query: "Find Goa reels",
  intent: "saved_content",
  userId: "user123",
  results: [...],
  timestamp: Timestamp
}
```

### `users` Collection
```javascript
{
  tokens: {
    youtube: "oauth_token",
    instagram: "oauth_token",
    facebook: "oauth_token"
  },
  updatedAt: Timestamp
}
```

## Advanced Features

### 1. Semantic Search
- Uses OpenAI embeddings for semantic understanding
- Finds content even with different wording
- Example: "beach videos" finds "ocean reels"

### 2. Multi-Platform Search
- Searches across all connected platforms simultaneously
- Combines results intelligently
- Platform-specific formatting

### 3. Content Caching
- Indexed content is cached in Firestore
- Faster subsequent searches
- Can work offline (with cached data)

### 4. Intelligent Routing
- LLM decides which platforms to search
- Can search all or specific platforms
- Handles platform-specific queries

## Limitations & Notes

1. **OAuth Required**: Users must authenticate to search their saved content
2. **API Rate Limits**: Respect platform API rate limits
3. **Embedding Costs**: OpenAI embeddings have usage costs
4. **Instagram Limitations**: Instagram Graph API has limited access
5. **Facebook Permissions**: Requires specific permissions for user posts

## Future Enhancements

1. **More Platforms**: TikTok, Twitter/X, Pinterest
2. **Advanced RAG**: Use vector databases (Pinecone, Weaviate)
3. **User Preferences**: Learn user preferences over time
4. **Content Recommendations**: Suggest similar content
5. **Real-time Sync**: Auto-sync new saved content

## Troubleshooting

### OpenAI not working
- Check API key is set correctly
- Verify billing is enabled on OpenAI account
- Check function logs for errors

### Platform APIs failing
- Verify OAuth tokens are valid
- Check token expiration
- Verify API permissions

### RAG search slow
- Consider using dedicated vector DB
- Limit embedding dimensions
- Add more indexes in Firestore

## Cost Considerations

- **OpenAI API**: ~$0.0001 per query (GPT-4) + $0.00002 per embedding
- **Firestore**: Storage + read/write operations
- **Platform APIs**: Usually free with rate limits
- **Cloud Functions**: Execution time + invocations

Estimated cost: ~$0.01-0.05 per search query (with OpenAI)

