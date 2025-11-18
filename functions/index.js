const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const cors = require('cors');
const axios = require('axios');

// Import services
const { parseIntentWithLLM, generateResponse, initializeLLM } = require('./services/llmService');
const { AgenticRouter } = require('./services/agenticRouter');
const { indexContent, syncPlatformContent } = require('./services/ragService');
const { getOrCreateUser, getUserTokensByIdentifier, linkPlatformToken, getConnectedPlatforms, recordUnifiedConsent } = require('./services/unifiedAuth');
const { syncAllPlatformContent } = require('./services/contentSync');
const { logQuery, logOAuth, logError, getRecentLogs, getSyncStatus, getErrorSummary } = require('./services/debugLogger');
const { directOAuthRoutes } = require('./services/directOAuth');
const { ProductSearchService } = require('./services/productSearchService');
const { VisionService } = require('./services/visionService');

admin.initializeApp();
const db = admin.firestore();
const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Direct OAuth routes (from Gemini v2 package - simpler popup-based OAuth)
app.use('/auth', directOAuthRoutes);

// LLM will be initialized on first use (runtime initialization)
// This ensures functions.config() is available

/**
 * Environment variables expected:
 * - OPENAI_API_KEY (for LLM and embeddings)
 * - YOUTUBE_API_KEY (for YouTube Data API)
 * - GOOGLE_MAPS_API_KEY (for Places API)
 */

// Generate or retrieve device token
function getDeviceToken(req) {
  return req.body.token || req.headers['x-device-token'] || 'anonymous';
}

/**
 * Get user OAuth tokens from Firestore
 * Uses unified auth - email/mobile as common identifier
 */
async function getUserTokens(userIdentifier) {
  try {
    // Try to get by identifier (email/mobile) first
    const tokens = await getUserTokensByIdentifier(userIdentifier);
    if (tokens.userId) {
      return tokens;
    }
    
    // Fallback to old method (device token)
    const userDoc = await db.collection('users').doc(userIdentifier).get();
    if (!userDoc.exists) {
      return { youtube: null, instagram: null, facebook: null };
    }
    const data = userDoc.data();
    return {
      youtube: data.tokens?.youtube || null,
      instagram: data.tokens?.instagram || null,
      facebook: data.tokens?.facebook || null
    };
  } catch (error) {
    console.error('Error getting user tokens:', error);
    return { youtube: null, instagram: null, facebook: null };
  }
}

/**
 * Main query endpoint with LLM + RAG + Agentic AI
 */
app.post('/api/query', async (req, res) => {
  try {
    const { query, text, token, location, userId, ig_access, yt_access, google_access } = req.body;
    
    // Support both 'query' and 'text' parameters (for compatibility)
    const queryText = query || text;
    
    if (!queryText) {
      return res.status(400).json({ error: 'Query is required' });
    }

    // Use device token as identifier
    const deviceToken = token || getDeviceToken(req);
    const userIdentifier = userId || deviceToken;
    
    // Check for direct access tokens (from client localStorage - Gemini v2 package style)
    // If tokens provided directly, use them; otherwise use stored tokens
    let directTokens = {};
    if (ig_access) directTokens.instagram = ig_access;
    if (yt_access) directTokens.youtube = yt_access;
    if (google_access) directTokens.google = google_access;
    const sessionId = `sess-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;

    // Save session to Firestore
    const sessionRef = db.collection('sessions').doc(sessionId);
    await sessionRef.set({
      session_id: sessionId,
      query: queryText,
      location: location || null,
      token: deviceToken,
      userId: userIdentifier,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'processing'
    });

    // Save user message
    await sessionRef.collection('messages').add({
      role: 'user',
      content: queryText,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Step 1: Parse intent using LLM
    const intentResult = await parseIntentWithLLM(queryText);
    const intent = intentResult.intent;
    
    // Get user tokens for logging
    let userTokens = await getUserTokens(userIdentifier);
    
    // Enhanced logging for debugging
    console.log(`[Query Debug] User: ${userIdentifier}, Query: "${queryText}"`);
    console.log(`[Query Debug] Intent: ${intent}, Platforms: ${JSON.stringify(intentResult.platforms || [])}, Keywords: ${JSON.stringify(intentResult.keywords || [])}`);
    console.log(`[Query Debug] User tokens - YouTube: ${!!userTokens.youtube}, Instagram: ${!!userTokens.instagram}, Facebook: ${!!userTokens.facebook}`);
    
    // Log query to debug system
    await logQuery(userIdentifier, queryText, intent, 0, {
      platforms: intentResult.platforms || [],
      keywords: intentResult.keywords || [],
      hasYouTubeToken: !!userTokens.youtube,
      hasInstagramToken: !!userTokens.instagram,
      hasFacebookToken: !!userTokens.facebook
    });

    let results = [];
    let responseText = '';

    // Step 2: Route based on intent
    // Also check for common query patterns that indicate saved content search
    const queryLower = queryText.toLowerCase();
    const isContentQuery = intent === 'saved_content' || 
                          intent === 'reel_search' || 
                          intent === 'video_search' ||
                          queryLower.includes('reel') ||
                          queryLower.includes('saved') ||
                          queryLower.includes('liked') ||
                          queryLower.includes('show me') ||
                          queryLower.includes('find') ||
                          queryLower.includes('search');
    
    if (isContentQuery) {
      // Use Agentic Router for multi-platform search
      // Router prioritizes indexed cache (RAG) for immediate response
      // Merge direct tokens if provided (from client localStorage)
      if (directTokens.instagram) userTokens.instagram = directTokens.instagram;
      if (directTokens.youtube) userTokens.youtube = directTokens.youtube;
      if (directTokens.google) userTokens.google = directTokens.google;
      
      const router = new AgenticRouter(userTokens);
      
      console.log(`[Query Debug] Starting search with router for user ${userIdentifier}`);
      const searchResults = await router.routeQuery(queryText, userIdentifier, intentResult);
      results = searchResults.results || [];
      
      console.log(`[Query Debug] Search completed - Found ${results.length} results (${searchResults.fromCache || 0} from cache, ${searchResults.fromAPI || 0} from API)`);
      
      // Log query results to debug system
      await logQuery(userIdentifier, queryText, intent, results.length, {
        fromCache: searchResults.fromCache || 0,
        fromAPI: searchResults.fromAPI || 0,
        platformsSearched: intentResult.platforms || []
      });
      
      // Log cache hit rate for monitoring
      if (searchResults.fromCache > 0) {
        console.log(`[Query] User ${userIdentifier}: ${searchResults.fromCache} results from cache, ${searchResults.fromAPI} from API`);
      }

      // Separate auth-required messages from actual results
      const authRequired = results.filter(r => r.requiresAuth || r.type === 'auth_required');
      const publicResults = results.filter(r => !r.requiresAuth && r.type !== 'auth_required');

      // Index new results for future RAG searches (only non-auth results)
      for (const result of publicResults.slice(0, 5)) {
        if (result.platform && result.url && !result._note) {
          await indexContent(result, userIdentifier, result.platform);
        }
      }

      // Generate natural language response using LLM
      if (authRequired.length > 0 && publicResults.length === 0) {
        responseText = 'To search your saved content, please connect your social media accounts. ' +
          'Platforms requiring connection: ' + authRequired.map(m => m.platform).join(', ') + '.';
      } else if (authRequired.length > 0) {
        responseText = await generateResponse(queryText, publicResults) + 
          ' Note: Some platforms require account connection to search your saved content.';
      } else {
        responseText = await generateResponse(queryText, results);
        // Add note about public vs saved if YouTube public results
        if (results.some(r => r._note)) {
          responseText += ' (Note: Showing public videos. Connect your account to search your saved content.)';
        }
      }
      
      // Combine results with auth messages
      results = [...publicResults, ...authRequired];
      
    } else if (intent === 'product_search') {
      // Product search across multiple e-commerce platforms
      console.log(`[Query] Product search for: "${queryText}"`);
      const productService = new ProductSearchService();
      const productResults = await productService.searchProducts(queryText, 20);
      const verifiedProducts = productService.verifyListings(productResults);
      
      results = verifiedProducts.map(product => ({
        platform: product.platform,
        title: product.title,
        price: product.price ? `${product.currency} ${product.price}` : 'Price not available',
        availability: product.availability_label,
        shipping: `${product.shipping_days} days`,
        link: product.link,
        score: product.score,
        type: 'product'
      }));
      
      responseText = await generateResponse(queryText, results);
      if (results.length === 0) {
        responseText = `I couldn't find any products matching "${queryText}". Try searching with different keywords or check if product search APIs are configured.`;
      }
      
      await logQuery(userIdentifier, queryText, intent, results.length, {
        platforms: verifiedProducts.map(p => p.platform)
      });
      
    } else if (intent === 'vision_search') {
      // Image analysis using Google Vision API
      console.log(`[Query] Vision search requested`);
      const imageBase64 = req.body.image || req.body.image_base64;
      
      if (!imageBase64) {
        responseText = 'Please provide an image to analyze. Send the image as base64 encoded data in the "image" or "image_base64" field.';
        return res.json({
          success: false,
          response: responseText,
          results: []
        });
      }
      
      const visionService = new VisionService();
      const visionResult = await visionService.analyzeImage(imageBase64);
      
      if (visionResult.error && !visionResult.mock) {
        responseText = `Error analyzing image: ${visionResult.error}`;
      } else if (visionResult.mock) {
        responseText = 'Vision API is not configured. Please set GOOGLE_VISION_KEY in Firebase Functions config.';
      } else {
        const labelsText = visionResult.labels.length > 0 
          ? `Detected: ${visionResult.labels.join(', ')}`
          : 'No labels detected';
        const ocrText = visionResult.ocr 
          ? `\n\nText found: ${visionResult.ocr}`
          : '';
        responseText = `${labelsText}${ocrText}`;
        
        results = [{
          type: 'vision',
          labels: visionResult.labels,
          ocr: visionResult.ocr,
          platform: 'Google Vision API'
        }];
      }
      
      await logQuery(userIdentifier, queryText, intent, results.length, {
        labelsCount: visionResult.labels?.length || 0,
        hasOcr: !!visionResult.ocr
      });
      
    } else if (intent === 'link_analysis') {
      // Link intelligence - extract metadata from URLs
      console.log(`[Query] Link analysis requested`);
      
      // Extract URL from query or intent result
      let urlToAnalyze = intentResult.url;
      if (!urlToAnalyze) {
        // Try to extract URL from query text
        const urlRegex = /(https?:\/\/[^\s]+)/g;
        const matches = queryText.match(urlRegex);
        if (matches && matches.length > 0) {
          urlToAnalyze = matches[0];
        }
      }
      
      if (!urlToAnalyze) {
        responseText = 'Please provide a URL to analyze. You can paste a link or say "analyze this link: [URL]".';
        return res.json({
          success: false,
          response: responseText,
          results: []
        });
      }
      
      const LinkIntelligenceService = require('./services/linkIntelligenceService');
      const linkService = new LinkIntelligenceService();
      
      // Get user tokens for authenticated platforms
      const userTokens = await getUserTokens(userIdentifier);
      const accessToken = urlToAnalyze.includes('instagram.com') ? userTokens.instagram :
                         urlToAnalyze.includes('facebook.com') ? userTokens.facebook :
                         urlToAnalyze.includes('youtube.com') || urlToAnalyze.includes('youtu.be') ? userTokens.youtube :
                         null;
      
      const linkResult = await linkService.analyzeLink(urlToAnalyze, accessToken);
      
      if (linkResult.error) {
        responseText = `Error analyzing link: ${linkResult.error}`;
        results = [{
          type: 'link_analysis',
          platform: linkResult.platform || 'unknown',
          url: urlToAnalyze,
          error: linkResult.error
        }];
      } else {
        // Format response
        const platformName = linkResult.platform.charAt(0).toUpperCase() + linkResult.platform.slice(1);
        let responseParts = [`📎 ${platformName} Link Analysis:`];
        
        if (linkResult.title) {
          responseParts.push(`\n📌 Title: ${linkResult.title}`);
        }
        if (linkResult.description) {
          responseParts.push(`\n📝 Description: ${linkResult.description.substring(0, 200)}${linkResult.description.length > 200 ? '...' : ''}`);
        }
        if (linkResult.channelTitle) {
          responseParts.push(`\n👤 Channel/Author: ${linkResult.channelTitle}`);
        }
        if (linkResult.publishedAt) {
          responseParts.push(`\n📅 Published: ${new Date(linkResult.publishedAt).toLocaleDateString()}`);
        }
        if (linkResult.viewCount) {
          responseParts.push(`\n👁️ Views: ${parseInt(linkResult.viewCount).toLocaleString()}`);
        }
        if (linkResult.likeCount) {
          responseParts.push(`\n👍 Likes: ${parseInt(linkResult.likeCount).toLocaleString()}`);
        }
        
        responseText = responseParts.join('\n');
        
        results = [{
          type: 'link_analysis',
          platform: linkResult.platform,
          url: urlToAnalyze,
          title: linkResult.title,
          description: linkResult.description,
          thumbnail: linkResult.thumbnail,
          metadata: linkResult.metadata || {}
        }];
      }
      
      await logQuery(userIdentifier, queryText, intent, results.length, {
        platform: linkResult.platform || 'unknown',
        hasMetadata: !linkResult.error
      });
      
    } else if (intent === 'nearby_restaurant' || intent === 'nearby_search') {
      // Call Google Places Nearby Search
      const { fetchPlacesDirect } = require('./services/directFetch');
      return fetchPlacesDirect(req, res, intentResult, location);
      
    } else if (intent === 'recall' || intent === 'recall_visit') {
      // Call recall logic (timeline)
      const { recallVisitDirect } = require('./services/directFetch');
      return recallVisitDirect(req, res, intentResult, google_access || directTokens.google);
      
    } else {
      // General query - try to help
      responseText = `I understand you're asking: "${queryText}". I can help you find nearby places, recall past visits, or search your saved social media content (videos, reels, posts) from YouTube, Instagram, Facebook, and more. What would you like to search?`;
    }

    // Save bot response
    await sessionRef.collection('messages').add({
      role: 'assistant',
      content: responseText,
      results: results,
      intent: intent,
      timestamp: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update session with results
    await sessionRef.update({
      status: 'completed',
      results: results,
      intent: intent
    });

    res.json({
      session_id: sessionId,
      response: responseText,
      results: results,
      intent: intent,
      platforms_searched: intentResult.platforms || []
    });

  } catch (error) {
    console.error('Error processing query:', error);
    const userIdentifier = req.body.token || getDeviceToken(req);
    await logError(error, { endpoint: '/api/query', query: req.body.query || req.body.text }, userIdentifier);
    res.status(500).json({ error: 'Internal server error', message: error.message });
  }
});

/**
 * Sync content from platforms to Firestore index
 * Fetches ALL saved content and indexes it
 */
app.post('/api/sync', async (req, res) => {
  try {
    const { userId, platform, token } = req.body;

    const identifier = userId || token;
    if (!identifier || !platform) {
      return res.status(400).json({ error: 'userId/token and platform are required' });
    }

    // Get token from user if not provided
    let accessToken = token;
    if (!accessToken) {
      const userTokens = await getUserTokensByIdentifier(identifier);
      accessToken = userTokens[platform];
    }

    if (!accessToken) {
      return res.status(400).json({ error: `No ${platform} token found. Please connect the platform first.` });
    }

    // Sync all content from platform
    const syncResult = await syncAllPlatformContent(identifier, platform, accessToken);

    // Check if error requires reconnection
    const requiresReconnect = syncResult.error?.includes('expired') || 
                              syncResult.error?.includes('invalid') ||
                              syncResult.error?.includes('reconnect');

    res.json({
      success: syncResult.success,
      platform: platform,
      itemsFetched: syncResult.itemsFetched || 0,
      itemsIndexed: syncResult.itemsIndexed || 0,
      message: syncResult.message || `Synced ${syncResult.itemsIndexed} items from ${platform}`,
      syncedAt: syncResult.syncedAt || new Date().toISOString(),
      ready: syncResult.success && syncResult.itemsIndexed > 0, // Ready to search
      requiresReconnect: requiresReconnect || false,
      error: syncResult.error || null
    });

  } catch (error) {
    console.error('Sync error:', error);
    res.status(500).json({ error: 'Sync failed', message: error.message });
  }
});

/**
 * Sync all platforms for a user
 */
app.post('/api/sync-all', async (req, res) => {
  try {
    const { userId, token } = req.body;

    const identifier = userId || token;
    if (!identifier) {
      return res.status(400).json({ error: 'userId or token is required' });
    }

    // Get all user tokens
    const userTokens = await getUserTokensByIdentifier(identifier);
    
    if (!userTokens.youtube && !userTokens.instagram && !userTokens.facebook) {
      return res.status(400).json({ error: 'No platforms connected. Please connect platforms first.' });
    }

    // Sync all platforms
    const { syncAllPlatformsForUser } = require('./services/contentSync');
    const results = await syncAllPlatformsForUser(identifier, userTokens);

    const totalFetched = results.reduce((sum, r) => sum + (r.itemsFetched || 0), 0);
    const totalIndexed = results.reduce((sum, r) => sum + (r.itemsIndexed || 0), 0);
    
    const allReady = results.every(r => r.success && r.itemsIndexed > 0);

    res.json({
      success: true,
      message: `Synced ${totalIndexed} items from ${results.length} platform(s)`,
      results: results,
      totalFetched: totalFetched,
      totalIndexed: totalIndexed,
      ready: allReady, // All platforms ready to search
      syncedAt: new Date().toISOString()
    });

  } catch (error) {
    console.error('Sync all error:', error);
    res.status(500).json({ error: 'Sync failed', message: error.message });
  }
});

/**
 * Unified Authentication - Connect user with email/mobile
 */
app.post('/api/auth/connect', async (req, res) => {
  try {
    const { email, mobile, platforms = ['youtube', 'instagram', 'facebook'] } = req.body;

    if (!email && !mobile) {
      return res.status(400).json({ error: 'email or mobile is required' });
    }

    const identifier = email || mobile;
    const type = email ? 'email' : 'mobile';
    
    // Create or get user
    const user = await getOrCreateUser(identifier, type);
    
    // Record unified consent
    await recordUnifiedConsent(identifier, platforms);
    
    // Get connected platforms status
    const status = await getConnectedPlatforms(identifier);

    res.json({ 
      success: true, 
      userId: identifier,
      message: 'User connected. Now connect individual platforms via OAuth.',
      connectedPlatforms: status.connected,
      disconnectedPlatforms: status.disconnected
    });

  } catch (error) {
    console.error('Connect error:', error);
    res.status(500).json({ error: 'Failed to connect user', message: error.message });
  }
});

/**
 * Save OAuth tokens for user (unified by email/mobile)
 */
app.post('/api/auth/save-tokens', async (req, res) => {
  try {
    const { userId, email, mobile, platform, token, accessToken, platformUserId } = req.body;

    // Use email/mobile as identifier if provided
    const identifier = email || mobile || userId;
    
    // Support both 'token' and 'accessToken' parameter names
    const oauthToken = accessToken || token;
    
    if (!identifier || !platform || !oauthToken) {
      console.error('[Save Tokens] Missing required fields:', { identifier: !!identifier, platform, oauthToken: !!oauthToken });
      return res.status(400).json({ error: 'userId/email/mobile, platform, and token/accessToken are required' });
    }

    console.log(`[Save Tokens] Saving token for platform: ${platform}, user: ${identifier}, token length: ${oauthToken.length}`);
    
    // Link platform token to user
    await linkPlatformToken(identifier, platform, oauthToken, platformUserId);
    
    console.log(`[Save Tokens] ✅ Token saved successfully for ${platform}`);
    
    // Get updated status
    const status = await getConnectedPlatforms(identifier);

    res.json({ 
      success: true, 
      message: `Token saved for ${platform}`,
      connectedPlatforms: status.connected,
      disconnectedPlatforms: status.disconnected
    });

  } catch (error) {
    console.error('Token save error:', error);
    res.status(500).json({ error: 'Failed to save token', message: error.message });
  }
});

/**
 * Get connection status for user (by device token)
 */
app.get('/api/auth/status', async (req, res) => {
  try {
    const { token, userId } = req.query;
    const identifier = userId || token;
    
    if (!identifier) {
      return res.status(400).json({ error: 'token or userId is required' });
    }

    const status = await getConnectedPlatforms(identifier);
    const tokens = await getUserTokensByIdentifier(identifier);

    res.json({
      userId: identifier,
      connectedPlatforms: status.connected || [],
      disconnectedPlatforms: status.disconnected || [],
      hasTokens: {
        youtube: !!tokens.youtube,
        instagram: !!tokens.instagram,
        facebook: !!tokens.facebook
      }
    });

  } catch (error) {
    console.error('Status error:', error);
    res.status(500).json({ error: 'Failed to get status', message: error.message });
  }
});

// OAuth is handled by direct routes in /auth/* (Gemini v2 approach)

// OAuth callbacks are handled by direct routes in /auth/*/callback (Gemini v2 approach)
// Tokens are returned to client via postMessage, then saved to backend if device token available

app.post('/api/nearby', async (req, res) => {
  const { lat, lng, type } = req.body;
  const places = await searchPlaces({lat,lng}, type||'restaurant');
  res.json({ results: places });
});

app.post('/api/recall', async (req, res) => {
  const { token, location } = req.body;
  const last = await recallLastVisit(token, location);
  res.json({ last_visit: last });
});

async function searchPlaces(location, type) {
  // Mock response. Replace with Google Places API call using GOOGLE_MAPS_API_KEY
  const lat = location?.lat || 12.9716;
  const lng = location?.lng || 77.5946;
  
  return [
    { 
      platform: 'maps', 
      title: 'Empire Restaurant', 
      distance_m: 400, 
      rating: 4.3, 
      open_now: true, 
      url: `https://maps.google.com/?q=${lat},${lng}` 
    },
    { 
      platform: 'zomato', 
      title: 'Tandoori Treats', 
      distance_m: 650, 
      rating: 4.1, 
      open_now: true, 
      url: '' 
    }
  ];
}

async function recallLastVisit(token, location) {
  // Mock logic: In production, implement Google Timeline API fetch with OAuth token.
  return { 
    platform: 'google_timeline',
    place: 'Empire Restaurant', 
    date: '2025-08-20T20:12:00Z', 
    source: 'google_timeline',
    location: location
  };
}

/**
 * Debug endpoint - Get logs for testing
 */
app.get('/api/debug/logs', async (req, res) => {
  try {
    const { token, limit = 50 } = req.query;
    const userIdentifier = token || 'anonymous';
    
    const logs = await getRecentLogs(userIdentifier, parseInt(limit));
    
    res.json({
      success: true,
      userId: userIdentifier,
      logs: logs,
      count: logs.length
    });
  } catch (error) {
    console.error('Debug logs error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Debug endpoint - Get sync status
 */
app.get('/api/debug/sync-status', async (req, res) => {
  try {
    const { token } = req.query;
    const userIdentifier = token || 'anonymous';
    
    const status = await getSyncStatus(userIdentifier);
    
    res.json({
      success: true,
      userId: userIdentifier,
      syncStatus: status
    });
  } catch (error) {
    console.error('Debug sync status error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Debug endpoint - Get error summary
 */
app.get('/api/debug/errors', async (req, res) => {
  try {
    const { token, hours = 24 } = req.query;
    const userIdentifier = token || 'anonymous';
    
    const errors = await getErrorSummary(userIdentifier, parseInt(hours));
    
    res.json({
      success: true,
      userId: userIdentifier,
      errors: errors,
      count: errors.length
    });
  } catch (error) {
    console.error('Debug errors error:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * Debug endpoint - Check sync status and content index
 */
app.get('/api/debug/status', async (req, res) => {
  try {
    const { token } = req.query;
    const userIdentifier = token || 'anonymous';
    
    // Get user tokens
    const userTokens = await getUserTokens(userIdentifier);
    
    // Check content index count
    const contentSnapshot = await db.collection('content_index')
      .where('userId', '==', userIdentifier)
      .limit(1)
      .get();
    
    // Get all content to count (limit to reasonable number for performance)
    const allContent = await db.collection('content_index')
      .where('userId', '==', userIdentifier)
      .limit(1000)
      .get();
    
    // Check sync status
    const syncStatus = {
      youtube: {
        connected: !!userTokens.youtube,
        tokenLength: userTokens.youtube ? userTokens.youtube.length : 0
      },
      instagram: {
        connected: !!userTokens.instagram,
        tokenLength: userTokens.instagram ? userTokens.instagram.length : 0
      },
      facebook: {
        connected: !!userTokens.facebook,
        tokenLength: userTokens.facebook ? userTokens.facebook.length : 0
      }
    };
    
    res.json({
      userIdentifier,
      tokens: syncStatus,
      contentIndexed: allContent.size,
      hasContent: !contentSnapshot.empty,
      message: 'Debug status retrieved successfully'
    });
  } catch (error) {
    console.error('Debug status error:', error);
    res.status(500).json({ error: error.message });
  }
});

exports.api = functions.https.onRequest(app);

// Export scheduled functions (lazy load to avoid initialization timeout)
// These are also exported from scheduled/autoSync.js, but we include them here for explicit visibility
try {
  const scheduledFunctions = require('./scheduled/autoSync');
  exports.autoSyncAllUsers = scheduledFunctions.autoSyncAllUsers;
  exports.autoSyncUser = scheduledFunctions.autoSyncUser;
} catch (error) {
  console.warn('Scheduled functions not available:', error.message);
}
