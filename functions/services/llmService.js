/**
 * LLM Service - Supports both Google Gemini and OpenAI
 * Defaults to Gemini (cheaper, better Google integration)
 * Falls back to OpenAI if Gemini not configured
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
const OpenAI = require('openai');
const functions = require('firebase-functions');

let gemini = null;
let openai = null;
let useGemini = true; // Default to Gemini

/**
 * Initialize LLM providers
 */
function initializeLLM() {
  let geminiInitialized = false;
  let openaiInitialized = false;

  // Try Gemini first (preferred)
  const geminiKey = process.env.GEMINI_API_KEY || (typeof functions !== 'undefined' && functions.config().gemini?.key);
  if (geminiKey) {
    try {
      gemini = new GoogleGenerativeAI(geminiKey);
      useGemini = true;
      geminiInitialized = true;
      console.log('✅ Google Gemini initialized (primary)');
    } catch (error) {
      console.error('Gemini initialization error:', error);
    }
  }

  // Also initialize OpenAI as fallback
  const openaiKey = process.env.OPENAI_API_KEY || (typeof functions !== 'undefined' && functions.config().openai?.key);
  if (openaiKey) {
    try {
      openai = new OpenAI({ apiKey: openaiKey });
      openaiInitialized = true;
      if (geminiInitialized) {
        console.log('✅ OpenAI initialized (fallback)');
      } else {
        useGemini = false;
        console.log('✅ Using OpenAI for LLM (Gemini not available)');
      }
    } catch (error) {
      console.error('OpenAI initialization error:', error);
    }
  }

  if (geminiInitialized || openaiInitialized) {
    return true;
  }

  console.log('⚠️  No LLM API key configured. Using simple fallback.');
  return false;
}

/**
 * Enhanced intent parsing using LLM (Gemini or OpenAI)
 */
async function parseIntentWithLLM(query) {
  // Initialize LLM on first use (runtime initialization)
  if (!gemini && !openai) {
    initializeLLM();
  }
  
  if (!gemini && !openai) {
    return parseIntentSimple(query);
  }

  const systemPrompt = `You are an intent classifier for a smart search chatbot. Classify user queries into one of these intents:
- saved_content: User wants to search saved videos/reels/content from social media platforms (YouTube, Instagram, Facebook, etc.). This includes queries like "show me reels", "find saved videos", "goa reels", "liked videos", "saved content", etc.
- reel_search: User wants to search for reels (Instagram reels, YouTube Shorts, etc.)
- video_search: User wants to search for videos (YouTube videos, etc.)
- nearby_restaurant: User wants to find nearby restaurants or places
- recall: User wants to recall past visits or location history
- general: General conversation or unclear intent

IMPORTANT: If the query mentions "reel", "reels", "saved", "liked", "show me", "find", or asks about content from YouTube/Instagram/Facebook, classify it as "saved_content" or "reel_search" or "video_search".

Respond with JSON only: {"intent": "intent_name", "platforms": ["platform1", "platform2"], "keywords": ["keyword1", "keyword2"]}`;

  try {
    // Try Gemini first (primary)
    if (useGemini && gemini) {
      try {
        const model = gemini.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });
        const result = await model.generateContent([
          { role: 'user', parts: [{ text: `${systemPrompt}\n\nUser query: ${query}` }] }
        ]);
        
        const response = await result.response;
        const text = response.text();
        
        // Extract JSON from response
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          return JSON.parse(jsonMatch[0]);
        }
      } catch (geminiError) {
        console.error('Gemini error, falling back to OpenAI:', geminiError.message);
        // Fall through to OpenAI fallback
      }
    }
    
    // Fallback to OpenAI if Gemini failed or not available
    if (openai) {
      try {
        const response = await openai.chat.completions.create({
          model: 'gpt-4-turbo-preview',
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: query }
          ],
          temperature: 0.3,
          response_format: { type: 'json_object' }
        });

        return JSON.parse(response.choices[0].message.content);
      } catch (openaiError) {
        console.error('OpenAI error:', openaiError.message);
        // Fall through to simple parsing
      }
    }
  } catch (error) {
    console.error('LLM error:', error);
  }

  return parseIntentSimple(query);
}

/**
 * Simple fallback intent parsing
 */
function parseIntentSimple(query) {
  const q = query.toLowerCase();
  const platforms = [];
  const keywords = [];

  // Detect platforms
  if (q.includes('youtube') || q.includes('yt')) platforms.push('youtube');
  if (q.includes('instagram') || q.includes('insta') || q.includes('reel')) platforms.push('instagram');
  if (q.includes('facebook') || q.includes('fb')) platforms.push('facebook');
  if (q.includes('tiktok')) platforms.push('tiktok');

  // Extract keywords
  const commonWords = ['find', 'search', 'show', 'get', 'saved', 'watch', 'video', 'reel', 'movie'];
  q.split(' ').forEach(word => {
    if (!commonWords.includes(word) && word.length > 2) {
      keywords.push(word);
    }
  });

  if (q.includes('reel') || q.includes('saved') || q.includes('video') || q.includes('youtube') || q.includes('instagram') || platforms.length > 0) {
    return { intent: 'saved_content', platforms, keywords };
  }
  if (q.includes('eat') || q.includes('restaurant') || q.includes('nearby') || q.includes('food')) {
    return { intent: 'nearby_restaurant', platforms: [], keywords };
  }
  if (q.includes('recall') || q.includes('last visit') || q.includes('remember')) {
    return { intent: 'recall', platforms: [], keywords };
  }
  return { intent: 'general', platforms: [], keywords };
}

/**
 * Generate search query embeddings for RAG
 * Uses Gemini embeddings (text-embedding-004) or OpenAI (text-embedding-3-small)
 */
async function generateEmbedding(text) {
  // Initialize LLM on first use (runtime initialization)
  if (!gemini && !openai) {
    initializeLLM();
  }
  
  if (!gemini && !openai) {
    return null;
  }

  try {
    // Try Gemini first (primary)
    if (useGemini && gemini) {
      try {
        const model = gemini.getGenerativeModel({ model: 'models/text-embedding-004' });
        const result = await model.embedContent(text);
        // Extract embedding from result
        if (result.embedding) {
          return result.embedding.values || result.embedding;
        }
        // Fallback: try alternative response structure
        const embedding = result.response?.embedding?.values || result.response?.embedding;
        if (embedding && embedding.length > 0) {
          return embedding;
        }
      } catch (geminiError) {
        console.error('Gemini embedding error, falling back to OpenAI:', geminiError.message);
        // Fall through to OpenAI fallback
      }
    }
    
    // Fallback to OpenAI embeddings
    if (openai) {
      try {
        const response = await openai.embeddings.create({
          model: 'text-embedding-3-small',
          input: text
        });
        return response.data[0].embedding;
      } catch (openaiError) {
        console.error('OpenAI embedding error:', openaiError.message);
      }
    }
  } catch (error) {
    console.error('Embedding generation error:', error);
  }
  
  return null;
}

/**
 * Use LLM to generate natural language response
 */
async function generateResponse(query, results) {
  // Initialize LLM on first use (runtime initialization)
  if (!gemini && !openai) {
    initializeLLM();
  }
  
  if (!gemini && !openai) {
    return formatSimpleResponse(results);
  }

  const prompt = `User query: "${query}"\n\nResults found: ${JSON.stringify(results, null, 2)}\n\nGenerate a helpful, friendly response summarizing these results.`;

  try {
    // Try Gemini first (primary)
    if (useGemini && gemini) {
      try {
        const model = gemini.getGenerativeModel({ model: 'gemini-2.0-flash-exp' });
        const result = await model.generateContent([
          { role: 'user', parts: [{ text: `You are a helpful assistant. ${prompt}` }] }
        ]);
        
        const response = await result.response;
        return response.text();
      } catch (geminiError) {
        console.error('Gemini response error, falling back to OpenAI:', geminiError.message);
        // Fall through to OpenAI fallback
      }
    }
    
    // Fallback to OpenAI if Gemini failed or not available
    if (openai) {
      try {
        const response = await openai.chat.completions.create({
          model: 'gpt-4-turbo-preview',
          messages: [
            {
              role: 'system',
              content: 'You are a helpful assistant that presents search results in a friendly, natural way. Summarize the results and highlight key information.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7
        });

        return response.choices[0].message.content;
      } catch (openaiError) {
        console.error('OpenAI response error:', openaiError.message);
        // Fall through to simple response
      }
    }
  } catch (error) {
    console.error('Response generation error:', error);
  }
  
  return formatSimpleResponse(results);
}

function formatSimpleResponse(results) {
  if (!results || results.length === 0) {
    return 'I couldn\'t find any results for your query.';
  }
  return `I found ${results.length} result${results.length > 1 ? 's' : ''} for you!`;
}

module.exports = {
  parseIntentWithLLM,
  generateEmbedding,
  generateResponse,
  initializeLLM
};
