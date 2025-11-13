/**
 * Agentic AI Router - Routes queries to appropriate platform services
 * Acts as an intelligent agent that decides which platforms to search
 */

const { YouTubeService, InstagramService, FacebookService } = require('./platformServices');
const { searchContent } = require('./ragService');
const { parseIntentWithLLM } = require('./llmService');

/**
 * Agentic Router - Main routing logic
 */
class AgenticRouter {
  constructor(userTokens) {
    // userTokens: { youtube: token, instagram: token, facebook: token }
    this.services = {
      youtube: userTokens.youtube ? new YouTubeService(null, userTokens.youtube) : new YouTubeService(),
      instagram: new InstagramService(userTokens.instagram),
      facebook: new FacebookService(userTokens.facebook)
    };
  }

  /**
   * Route query to appropriate platforms using agentic decision making
   */
  async routeQuery(query, userId, intentResult) {
    const { intent, platforms, keywords } = intentResult;

    if (intent !== 'saved_content') {
      return { results: [], message: 'This query is not for saved content search' };
    }

    // Determine which platforms to search
    const platformsToSearch = this.determinePlatforms(platforms, query);
    
    // Search in parallel across platforms
    const searchPromises = [];
    
    // PRIORITY 1: Search indexed content first (RAG - from cache)
    // This provides immediate results from synced content
    searchPromises.push(
      searchContent(query, userId, platformsToSearch, 20)
        .then(results => {
          console.log(`[RAG Search] Found ${results.length} results from indexed cache for user ${userId}`);
          return { source: 'rag', results, priority: 1 };
        })
        .catch(err => {
          console.error('RAG search error:', err);
          return { source: 'rag', results: [], priority: 1 };
        })
    );

    // PRIORITY 2: Search live APIs (only if needed or for fresh content)
    // This is slower but provides real-time results
    for (const platform of platformsToSearch) {
      if (this.services[platform]) {
        searchPromises.push(
          this.searchPlatform(platform, query)
            .then(results => ({ source: 'api', platform, results, priority: 2 }))
            .catch(err => {
              console.error(`Error searching ${platform}:`, err);
              return { source: 'api', platform, results: [], priority: 2 };
            })
        );
      }
    }

    const searchResults = await Promise.all(searchPromises);

    // Aggregate and deduplicate results
    const aggregated = this.aggregateResults(searchResults, query);
    
    // Log search performance
    if (aggregated.fromCache > 0) {
      console.log(`[Search] User ${userId}: ${aggregated.fromCache} results from cache, ${aggregated.fromAPI} from API`);
    }
    
    return aggregated;
  }

  /**
   * Determine which platforms to search based on query and intent
   */
  determinePlatforms(explicitPlatforms, query) {
    const queryLower = query.toLowerCase();
    const platforms = new Set();

    // If platforms explicitly mentioned, use those
    if (explicitPlatforms && explicitPlatforms.length > 0) {
      explicitPlatforms.forEach(p => platforms.add(p));
    } else {
      // Auto-detect from query
      if (queryLower.includes('youtube') || queryLower.includes('yt') || queryLower.includes('video')) {
        platforms.add('youtube');
      }
      if (queryLower.includes('instagram') || queryLower.includes('insta') || queryLower.includes('reel')) {
        platforms.add('instagram');
      }
      if (queryLower.includes('facebook') || queryLower.includes('fb')) {
        platforms.add('facebook');
      }
    }

    // If no platform specified, search all available
    if (platforms.size === 0) {
      platforms.add('youtube');
      platforms.add('instagram');
      platforms.add('facebook');
    }

    return Array.from(platforms);
  }

  /**
   * Search a specific platform
   */
  async searchPlatform(platform, query) {
    switch (platform) {
      case 'youtube':
        return await this.services.youtube.searchSavedVideos(query, 10);
      case 'instagram':
        return await this.services.instagram.searchSavedContent(query, 10);
      case 'facebook':
        return await this.services.facebook.searchSavedContent(query, 10);
      default:
        return [];
    }
  }

  /**
   * Aggregate results from multiple sources and deduplicate
   * PRIORITY: RAG (indexed cache) results first, then API results
   */
  aggregateResults(searchResults, query) {
    const allResults = [];
    const seenUrls = new Set();
    const seenIds = new Set();

    // PRIORITY 1: RAG results (indexed content from cache) - FAST & IMMEDIATE
    // These come from the background sync, so they're already indexed and ready
    for (const result of searchResults) {
      if (result.source === 'rag' && result.priority === 1) {
        for (const item of result.results) {
          const key = item.url || item.id;
          if (key && !seenUrls.has(key) && !seenIds.has(key)) {
            seenUrls.add(key);
            if (item.id) seenIds.add(item.id);
            // Mark as from cache for user feedback
            item._fromCache = true;
            allResults.push(item);
          }
        }
      }
    }

    // PRIORITY 2: API results (live search) - SLOWER but fresh
    // Only add if not already in cache results
    for (const result of searchResults) {
      if (result.source === 'api' && result.priority === 2) {
        for (const item of result.results) {
          const key = item.url || item.id;
          if (key && !seenUrls.has(key) && !seenIds.has(key)) {
            seenUrls.add(key);
            if (item.id) seenIds.add(item.id);
            allResults.push(item);
          }
        }
      }
    }

    // Return results - cache results come first, then API results
    // This ensures immediate response from indexed content
    return { 
      results: allResults.slice(0, 20), // Return top 20 results
      fromCache: allResults.filter(r => r._fromCache).length,
      fromAPI: allResults.filter(r => !r._fromCache).length
    };
  }
}

module.exports = {
  AgenticRouter
};

