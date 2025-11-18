/**
 * Link Intelligence Service
 * Extracts metadata from URLs (YouTube, Instagram, Facebook, etc.)
 */

const axios = require('axios');
const functions = require('firebase-functions');

class LinkIntelligenceService {
  constructor() {
    // YouTube API key (optional, for better metadata)
    this.youtubeApiKey = process.env.YOUTUBE_API_KEY || 
      (typeof functions !== 'undefined' && functions.config().youtube?.key);
  }

  /**
   * Extract metadata from a URL
   * @param {string} url - The URL to analyze
   * @param {string} accessToken - Optional OAuth token for authenticated platforms
   * @returns {Promise<{platform: string, title: string, description: string, thumbnail: string, url: string, metadata: object}>}
   */
  async analyzeLink(url, accessToken = null) {
    if (!url) {
      return { error: 'No URL provided', platform: 'unknown' };
    }

    try {
      // Detect platform
      if (url.includes('youtube.com') || url.includes('youtu.be')) {
        return await this.analyzeYouTube(url, accessToken);
      } else if (url.includes('instagram.com')) {
        return await this.analyzeInstagram(url, accessToken);
      } else if (url.includes('facebook.com')) {
        return await this.analyzeFacebook(url, accessToken);
      } else {
        return await this.analyzeGeneric(url);
      }
    } catch (error) {
      console.error('[Link Intelligence] Error analyzing link:', error);
      return {
        error: error.message,
        platform: 'unknown',
        url: url
      };
    }
  }

  /**
   * Extract YouTube video metadata
   */
  async analyzeYouTube(url, accessToken = null) {
    try {
      // Extract video ID from URL
      let videoId = null;
      const youtubeRegex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/;
      const match = url.match(youtubeRegex);
      if (match) {
        videoId = match[1];
      }

      if (!videoId) {
        return {
          platform: 'youtube',
          url: url,
          error: 'Could not extract video ID from URL'
        };
      }

      // Try YouTube Data API first (if API key available)
      if (this.youtubeApiKey) {
        try {
          const apiUrl = `https://www.googleapis.com/youtube/v3/videos?id=${videoId}&part=snippet,contentDetails,statistics&key=${this.youtubeApiKey}`;
          const response = await axios.get(apiUrl);
          
          if (response.data.items && response.data.items.length > 0) {
            const video = response.data.items[0];
            return {
              platform: 'youtube',
              url: url,
              videoId: videoId,
              title: video.snippet.title,
              description: video.snippet.description,
              thumbnail: video.snippet.thumbnails?.high?.url || video.snippet.thumbnails?.default?.url,
              channelTitle: video.snippet.channelTitle,
              publishedAt: video.snippet.publishedAt,
              duration: video.contentDetails?.duration,
              viewCount: video.statistics?.viewCount,
              likeCount: video.statistics?.likeCount,
              metadata: {
                channelId: video.snippet.channelId,
                categoryId: video.snippet.categoryId,
                tags: video.snippet.tags || []
              }
            };
          }
        } catch (apiError) {
          console.warn('[Link Intelligence] YouTube API failed, trying oEmbed:', apiError.message);
        }
      }

      // Fallback to oEmbed API (no API key required)
      try {
        const oEmbedUrl = `https://www.youtube.com/oembed?url=${encodeURIComponent(url)}&format=json`;
        const oEmbedResponse = await axios.get(oEmbedUrl);
        const data = oEmbedResponse.data;
        
        return {
          platform: 'youtube',
          url: url,
          videoId: videoId,
          title: data.title,
          description: data.author_name ? `By ${data.author_name}` : '',
          thumbnail: data.thumbnail_url,
          channelTitle: data.author_name,
          metadata: {
            html: data.html,
            width: data.width,
            height: data.height
          }
        };
      } catch (oEmbedError) {
        console.warn('[Link Intelligence] YouTube oEmbed failed:', oEmbedError.message);
        // Return basic info
        return {
          platform: 'youtube',
          url: url,
          videoId: videoId,
          title: 'YouTube Video',
          description: 'Could not fetch metadata',
          thumbnail: `https://img.youtube.com/vi/${videoId}/maxresdefault.jpg`
        };
      }
    } catch (error) {
      console.error('[Link Intelligence] YouTube analysis error:', error);
      return {
        platform: 'youtube',
        url: url,
        error: error.message
      };
    }
  }

  /**
   * Extract Instagram post/reel metadata
   */
  async analyzeInstagram(url, accessToken = null) {
    try {
      // Extract shortcode from URL
      const instagramRegex = /instagram\.com\/(?:p|reel|tv)\/([A-Za-z0-9_-]+)/;
      const match = url.match(instagramRegex);
      const shortcode = match ? match[1] : null;

      if (!shortcode) {
        return {
          platform: 'instagram',
          url: url,
          error: 'Could not extract post ID from URL'
        };
      }

      // If access token provided, use Graph API
      if (accessToken) {
        try {
          // Try to get media by shortcode (requires Instagram Graph API)
          // Note: Instagram Graph API doesn't directly support shortcode lookup
          // This would require fetching user media and matching
          // For now, return basic info
          return {
            platform: 'instagram',
            url: url,
            shortcode: shortcode,
            title: 'Instagram Post',
            description: 'Instagram content (requires authentication for full metadata)',
            thumbnail: null,
            metadata: {
              shortcode: shortcode,
              authenticated: true
            }
          };
        } catch (apiError) {
          console.warn('[Link Intelligence] Instagram API failed:', apiError.message);
        }
      }

      // Fallback: Return basic info (Instagram doesn't have public oEmbed)
      return {
        platform: 'instagram',
        url: url,
        shortcode: shortcode,
        title: 'Instagram Post',
        description: 'Connect Instagram to view full metadata',
        thumbnail: null,
        metadata: {
          shortcode: shortcode,
          authenticated: false
        }
      };
    } catch (error) {
      console.error('[Link Intelligence] Instagram analysis error:', error);
      return {
        platform: 'instagram',
        url: url,
        error: error.message
      };
    }
  }

  /**
   * Extract Facebook post metadata
   */
  async analyzeFacebook(url, accessToken = null) {
    try {
      // Extract post ID from URL
      const facebookRegex = /facebook\.com\/(?:[^\/]+\/)?(?:posts|videos|photos)\/([A-Za-z0-9_-]+)/;
      const match = url.match(facebookRegex);
      const postId = match ? match[1] : null;

      if (!postId) {
        return {
          platform: 'facebook',
          url: url,
          error: 'Could not extract post ID from URL'
        };
      }

      // If access token provided, use Graph API
      if (accessToken) {
        try {
          const graphUrl = `https://graph.facebook.com/v18.0/${postId}?fields=message,created_time,from,full_picture&access_token=${accessToken}`;
          const response = await axios.get(graphUrl);
          const data = response.data;
          
          return {
            platform: 'facebook',
            url: url,
            postId: postId,
            title: data.from?.name || 'Facebook Post',
            description: data.message || '',
            thumbnail: data.full_picture,
            publishedAt: data.created_time,
            metadata: {
              from: data.from,
              authenticated: true
            }
          };
        } catch (apiError) {
          console.warn('[Link Intelligence] Facebook API failed:', apiError.message);
        }
      }

      // Fallback: Return basic info
      return {
        platform: 'facebook',
        url: url,
        postId: postId,
        title: 'Facebook Post',
        description: 'Connect Facebook to view full metadata',
        thumbnail: null,
        metadata: {
          postId: postId,
          authenticated: false
        }
      };
    } catch (error) {
      console.error('[Link Intelligence] Facebook analysis error:', error);
      return {
        platform: 'facebook',
        url: url,
        error: error.message
      };
    }
  }

  /**
   * Analyze generic URL (fallback)
   */
  async analyzeGeneric(url) {
    try {
      // Try to fetch page and extract basic metadata
      const response = await axios.get(url, {
        timeout: 5000,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
      });

      const html = response.data;
      
      // Extract title
      const titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i);
      const title = titleMatch ? titleMatch[1].trim() : 'Web Page';

      // Extract description
      const descMatch = html.match(/<meta[^>]*name=["']description["'][^>]*content=["']([^"']+)["']/i);
      const description = descMatch ? descMatch[1].trim() : '';

      // Extract thumbnail/og:image
      const imageMatch = html.match(/<meta[^>]*property=["']og:image["'][^>]*content=["']([^"']+)["']/i);
      const thumbnail = imageMatch ? imageMatch[1].trim() : null;

      return {
        platform: 'web',
        url: url,
        title: title,
        description: description,
        thumbnail: thumbnail,
        metadata: {
          analyzed: true
        }
      };
    } catch (error) {
      // Return basic info if fetch fails
      return {
        platform: 'web',
        url: url,
        title: 'Web Page',
        description: 'Could not fetch metadata',
        thumbnail: null,
        metadata: {
          analyzed: false,
          error: error.message
        }
      };
    }
  }
}

module.exports = LinkIntelligenceService;

