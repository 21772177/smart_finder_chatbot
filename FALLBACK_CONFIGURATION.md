# LLM Fallback Configuration

## ✅ Current Setup

**Both API keys are configured and active:**

- **Primary**: Google Gemini API (AIzaSyBD1p75QbjWwQVi2_qYdFPWbbLngJyzRxo)
- **Fallback**: OpenAI API (configured)

## How It Works

### 1. Initialization
- Both Gemini and OpenAI are initialized at startup
- Gemini is set as primary (`useGemini = true`)
- OpenAI is available as fallback

### 2. Runtime Fallback Logic

For each LLM operation (intent parsing, embeddings, response generation):

1. **Try Gemini first** (primary)
   - If successful → return result
   - If error → catch and log, continue to fallback

2. **Fallback to OpenAI** (if Gemini fails)
   - If successful → return result
   - If error → catch and log, continue to simple fallback

3. **Simple fallback** (if both fail)
   - Use rule-based parsing
   - Basic response formatting

### 3. Operations with Fallback

#### Intent Parsing (`parseIntentWithLLM`)
```
Gemini → OpenAI → Simple Rule-based
```

#### Embeddings (`generateEmbedding`)
```
Gemini Embeddings → OpenAI Embeddings → null
```

#### Response Generation (`generateResponse`)
```
Gemini → OpenAI → Simple Format
```

## Benefits

✅ **High Availability**: If Gemini is down, OpenAI takes over  
✅ **Cost Optimization**: Uses cheaper Gemini first  
✅ **Resilience**: Multiple layers of fallback  
✅ **No Downtime**: Always has a working solution  

## Logs

When deployed, you'll see:
```
✅ Google Gemini initialized (primary)
✅ OpenAI initialized (fallback)
```

If Gemini fails during a request:
```
Gemini error, falling back to OpenAI: [error message]
```

## Testing

Test the fallback by temporarily disabling Gemini (remove key), and the system will automatically use OpenAI.

## Configuration

Both keys are set in Firebase Functions config:
```bash
firebase functions:config:get
```

To update keys:
```bash
firebase functions:config:set gemini.key="NEW_KEY"
firebase functions:config:set openai.key="NEW_KEY"
firebase deploy --only functions
```

## Status

✅ **Deployed and Active**
- Function URL: https://us-central1-buildkit-1695f.cloudfunctions.net/api
- Both APIs initialized successfully
- Fallback logic active

