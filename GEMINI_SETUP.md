# Gemini vs OpenAI - Setup Guide

## Comparison

### Google Gemini (Recommended for this project)
✅ **96% cheaper** than GPT-4  
✅ **Better Google integration** (Firebase, YouTube API)  
✅ **More generous free tier** (60 requests/minute)  
✅ **Native Google Cloud integration**  
✅ **Good performance** for intent parsing and embeddings  
✅ **Multimodal capabilities** (text, images, video)

### OpenAI GPT-4
✅ **Slightly better** for complex reasoning  
✅ **More established** ecosystem  
✅ **Better documentation**  
❌ **Much more expensive** (~$2,250 vs $90 for same workload)  
❌ **Limited free tier**

## Recommendation

**Use Gemini** - It's perfect for this chatbot use case:
- Intent classification
- Embeddings for RAG
- Response generation
- Much cheaper
- Better Google services integration

## Setup Instructions

### Option 1: Use Gemini (Recommended)

1. **Get Gemini API Key**:
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Or [Google Cloud Console](https://console.cloud.google.com/)
   - Create API key for Gemini

2. **Set API Key**:
   ```bash
   # Using Firebase Functions config
   firebase functions:config:set gemini.key="AIzaSyBD1p75QbjWwQVi2_qYdFPWbbLngJyzRxo"
   firebase deploy --only functions
   ```

   Or set environment variable:
   ```bash
   export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
   ```

3. **Deploy**:
   ```bash
   firebase deploy --only functions
   ```

### Option 2: Use OpenAI (Fallback)

1. **Get OpenAI API Key**:
   - Go to [OpenAI Platform](https://platform.openai.com/api-keys)
   - Create API key

2. **Set API Key**:
   ```bash
   firebase functions:config:set openai.key=""
   firebase deploy --only functionssk-proj-mX_eBTftvn7Uj3QW9279h3mYXI8OO-j9AtsmQqdL3UB8DSuSNRHNf3qbqQkwfbhsz6Fotx8HXLT3BlbkFJTJgjhi4HJO0_DVfnTas0Lv29tzzn_kDYcnUOEbjnSZj8iHrmmok-hFO_0FWOGUFniLFIAAut8A
   ```

### Option 3: Use Both (Gemini preferred, OpenAI fallback)

Set both keys - Gemini will be used first, OpenAI as fallback:
```bash
firebase functions:config:set gemini.key="YOUR_GEMINI_API_KEY"
firebase functions:config:set openai.key="YOUR_OPENAI_API_KEY"
firebase deploy --only functions
```

## Cost Comparison

For 1 billion input tokens + 200 million output tokens:

| Provider | Model | Cost |
|----------|-------|------|
| **Gemini** | 2.0 Flash | **$90** |
| OpenAI | GPT-4 Turbo | **$2,250** |
| **Savings** | | **96% cheaper** |

## Models Used

### Gemini
- **Intent Parsing**: `gemini-2.0-flash-exp` (fast, cheap)
- **Response Generation**: `gemini-2.0-flash-exp` (fast, cheap)
- **Embeddings**: `text-embedding-004` (768 dimensions)

### OpenAI
- **Intent Parsing**: `gpt-4-turbo-preview`
- **Response Generation**: `gpt-4-turbo-preview`
- **Embeddings**: `text-embedding-3-small` (1536 dimensions)

## Testing

After setup, test with:
```bash
curl -X POST https://us-central1-buildkit-1695f.cloudfunctions.net/api/api/query \
  -H "Content-Type: application/json" \
  -d '{"query": "Find Goa travel reels I saved"}'
```

## Switching Between Providers

The code automatically detects which API keys are available:
1. **Gemini key present** → Uses Gemini
2. **Only OpenAI key** → Uses OpenAI
3. **No keys** → Falls back to simple rule-based parsing

You can force a specific provider by only setting that provider's key.

## Free Tier Limits

### Gemini
- **60 requests/minute** (free tier)
- **1,500 requests/day** (free tier)
- Very generous for development

### OpenAI
- **Limited free tier**
- Pay-as-you-go after free tier

## Recommendation

**Start with Gemini** - It's free, fast, and perfect for this use case. You can always add OpenAI later if needed.

