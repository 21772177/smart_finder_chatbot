/**
 * Platform Services - Integration with YouTube, Instagram, Facebook APIs
 */

const { google } = require('googleapis');
const axios = require('axios');
const functions = require('firebase-functions');

/**
 * YouTube Data API Service
 */
class YouTubeService {
  constructor(apiKey, accessToken) {
    this.apiKey = apiKey || process.env.YOUTUBE_API_KEY || (typeof functions !== 'undefined' && functions.config().youtube?.key);
    this.accessToken = accessToken;
    if (this.apiKey) {
      this.youtube = google.youtube({ version: 'v3', auth: this.apiKey });
    }
  }

  /**
   * Search user's saved/liked videos
   * Enhanced to also fetch liked videos and watch later (from Gemini v2 package)
   */
  async searchSavedVideos(query, maxResults = 10) {
    try {
      // Search in user's liked videos (requires OAuth)
      if (this.accessToken) {
        const oauth2Client = new google.auth.OAuth2();
        oauth2Client.setCredentials({ access_token: this.accessToken });
        const youtube = google.youtube({ version: 'v3', auth: oauth2Client });

        const results = [];
        
        // Fetch liked videos (from Gemini v2 package approach)
        try {
          const likedResponse = await youtube.videos.list({
            part: 'snippet',
            myRating: 'like',
            maxResults: 50
          });
          
          for (const video of likedResponse.data.items || []) {
            const title = video.snippet.title.toLowerCase();
            const description = (video.snippet.description || '').toLowerCase();
            const searchQuery = query.toLowerCase();
            
            if (!query || title.includes(searchQuery) || description.includes(searchQuery)) {
              results.push({
                platform: 'YouTube',
                id: video.id,
                title: video.snippet.title,
                description: video.snippet.description,
                thumbnail: video.snippet.thumbnails?.medium?.url || video.snippet.thumbnails?.default?.url,
                url: `https://www.youtube.com/watch?v=${video.id}`,
                channel: video.snippet.channelTitle,
                publishedAt: video.snippet.publishedAt,
                type: 'video',
                savedIn: 'Liked Videos'
              });
            }
          }
        } catch (e) {
          console.warn('Error fetching liked videos:', e.message);
        }
        
        // Fetch watch later playlist
        try {
          const wlResponse = await youtube.playlistItems.list({
            part: 'snippet',
            playlistId: 'WL',
            maxResults: 50
          });
          
          for (const item of wlResponse.data.items || []) {
            const title = item.snippet.title.toLowerCase();
            const description = (item.snippet.description || '').toLowerCase();
            const searchQuery = query.toLowerCase();
            
            if (!query || title.includes(searchQuery) || description.includes(searchQuery)) {
              results.push({
                platform: 'YouTube',
                id: item.snippet.resourceId.videoId,
                title: item.snippet.title,
                description: item.snippet.description,
                thumbnail: item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url,
                url: `https://www.youtube.com/watch?v=${item.snippet.resourceId.videoId}`,
                channel: item.snippet.channelTitle,
                publishedAt: item.snippet.publishedAt,
                type: 'video',
                savedIn: 'Watch Later'
              });
            }
          }
        } catch (e) {
          console.warn('Error fetching watch later:', e.message);
        }

        // Get user's playlists (saved videos)
        try {
          const playlistsResponse = await youtube.playlists.list({
            part: 'snippet,contentDetails',
            mine: true,
            maxResults: 50
          });

          for (const playlist of playlistsResponse.data.items || []) {
            // Search within playlist items
            const itemsResponse = await youtube.playlistItems.list({
              part: 'snippet',
              playlistId: playlist.id,
              maxResults: 50
            });

            for (const item of itemsResponse.data.items || []) {
              const title = item.snippet.title.toLowerCase();
              const description = (item.snippet.description || '').toLowerCase();
              const searchQuery = query.toLowerCase();

              if (!query || title.includes(searchQuery) || description.includes(searchQuery)) {
                results.push({
                  platform: 'YouTube',
                  id: item.snippet.resourceId.videoId,
                  title: item.snippet.title,
                  description: item.snippet.description,
                  thumbnail: item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url,
                  url: `https://www.youtube.com/watch?v=${item.snippet.resourceId.videoId}`,
                  channel: item.snippet.channelTitle,
                  publishedAt: item.snippet.publishedAt,
                  type: 'video',
                  savedIn: playlist.snippet.title
                });
              }
            }
          }
        } catch (e) {
          console.warn('Error fetching playlists:', e.message);
        }

        return results.slice(0, maxResults);
      } else {
        // Fallback: Search public YouTube (without OAuth)
        // Note: This searches PUBLIC videos, not user's saved content
        const publicResults = await this.searchPublicVideos(query, maxResults);
        // Add a note that these are public results
        if (publicResults.length > 0) {
          publicResults[0]._note = 'These are public YouTube videos. Connect your account to search your saved videos.';
        }
        return publicResults;
      }
    } catch (error) {
      console.error('YouTube search error:', error);
      return this.searchPublicVideos(query, maxResults);
    }
  }

  /**
   * Search public YouTube videos (fallback)
   */
  async searchPublicVideos(query, maxResults = 10) {
    // Check if YouTube API is available
    if (!this.youtube) {
      console.warn('YouTube API not initialized - API key may be missing');
      return [{
        platform: 'YouTube',
        title: 'YouTube API Key Required',
        message: 'YouTube API key is not configured. Please configure it to search public YouTube videos.',
        requiresAuth: false,
        type: 'api_key_required'
      }];
    }
    
    try {
      const response = await this.youtube.search.list({
        part: 'snippet',
        q: query,
        type: 'video',
        maxResults: maxResults,
        order: 'relevance'
      });

      return (response.data.items || []).map(item => ({
        platform: 'YouTube',
        id: item.id.videoId,
        title: item.snippet.title,
        description: item.snippet.description,
        thumbnail: item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url,
        url: `https://www.youtube.com/watch?v=${item.id.videoId}`,
        channel: item.snippet.channelTitle,
        publishedAt: item.snippet.publishedAt,
        type: 'video'
      }));
    } catch (error) {
      console.error('YouTube public search error:', error);
      return [];
    }
  }
}

/**
 * Instagram Graph API Service
 */
class InstagramService {
  constructor(accessToken) {
    this.accessToken = accessToken;
    this.baseUrl = 'https://graph.instagram.com';
  }

  /**
   * Search saved posts/reels
   * Enhanced to fetch user media (from Gemini v2 package)
   * Note: Instagram Basic Display API doesn't provide 'saved' or 'liked' lists
   * This fetches user's media as a best-effort proxy
   */
  async searchSavedContent(query, maxResults = 10) {
    if (!this.accessToken) {
      console.warn('Instagram access token not provided - cannot access saved content without OAuth');
      // Return a message result indicating OAuth is needed
      return [{
        platform: 'Instagram',
        title: 'Connect Instagram Required',
        message: 'To search your saved Instagram content, please connect your Instagram account via OAuth.',
        requiresAuth: true,
        type: 'auth_required'
      }];
    }
    
    try {
      // Fetch user's media (from Gemini v2 package approach)
      const axios = require('axios');
      const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${this.accessToken}`;
      const resp = await axios.get(url);
      const media = resp.data.data || [];
      
      // Filter for reels/videos and match query
      const queryLower = query ? query.toLowerCase() : '';
      const reels = media
        .filter(m => m.media_type === 'VIDEO' || (m.media_type === 'IMAGE' && m.thumbnail_url))
        .filter(m => {
          if (!query) return true;
          const caption = (m.caption || '').toLowerCase();
          return caption.includes(queryLower);
        })
        .slice(0, maxResults)
        .map(m => ({
          platform: 'Instagram',
          id: m.id,
          caption: m.caption || '',
          mediaType: m.media_type,
          mediaUrl: m.media_url,
          thumbnail: m.thumbnail_url || m.media_url,
          url: m.permalink,
          type: m.media_type === 'VIDEO' ? 'reel' : 'post'
        }));
      
      return reels;
    } catch (error) {
      console.error('Instagram search error:', error);
      return [{
        platform: 'Instagram',
        title: 'Error fetching Instagram content',
        message: error.message || 'Failed to fetch Instagram content',
        requiresAuth: false,
        type: 'error'
      }];
    }
  }
}

/**
 * Facebook Graph API Service
 */
class FacebookService {
  constructor(accessToken) {
    this.accessToken = accessToken;
    this.baseUrl = 'https://graph.facebook.com/v18.0';
  }

  /**
   * Search saved posts/videos
   */
  async searchSavedContent(query, maxResults = 10) {
    if (!this.accessToken) {
      console.warn('Facebook access token not provided - cannot access saved content without OAuth');
      // Return a message result indicating OAuth is needed
      return [{
        platform: 'Facebook',
        title: 'Connect Facebook Required',
        message: 'To search your saved Facebook content, please connect your Facebook account via OAuth.',
        requiresAuth: true,
        type: 'auth_required'
      }];
    }

    try {
      // Get user's saved posts
      const response = await axios.get(`${this.baseUrl}/me/saved`, {
        params: {
          access_token: this.accessToken,
          fields: 'id,message,story,created_time,permalink_url,attachments{media,subattachments}'
        }
      });

      const results = [];
      const searchQuery = query.toLowerCase();

      for (const item of response.data.data || []) {
        const message = (item.message || item.story || '').toLowerCase();
        if (message.includes(searchQuery)) {
          const mediaUrl = item.attachments?.data?.[0]?.media?.image?.src || 
                          item.attachments?.data?.[0]?.subattachments?.data?.[0]?.media?.image?.src;

          results.push({
            platform: 'Facebook',
            id: item.id,
            message: item.message || item.story,
            mediaUrl: mediaUrl,
            url: item.permalink_url,
            timestamp: item.created_time,
            type: 'post'
          });
        }
      }

      return results.slice(0, maxResults);
    } catch (error) {
      console.error('Facebook search error:', error);
      return [];
    }
  }
}

module.exports = {
  YouTubeService,
  InstagramService,
  FacebookService
};

