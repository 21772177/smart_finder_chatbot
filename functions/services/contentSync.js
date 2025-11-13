/**
 * Content Sync Service
 * Automatically scans and indexes ALL saved content from platforms
 * Runs when platform is connected and periodically to keep data fresh
 */

const { YouTubeService, InstagramService, FacebookService } = require('./platformServices');
const { syncPlatformContent, indexContent } = require('./ragService');

/**
 * Sync all saved content from a platform
 * Fetches everything and indexes it in Firestore
 */
async function syncAllPlatformContent(userId, platform, accessToken) {
  try {
    console.log(`[Background Sync] Starting full sync for ${platform} for user ${userId}`);
    
    let allContent = [];
    let service;
    
    // Initialize platform service
    switch (platform) {
      case 'youtube':
        service = new YouTubeService(null, accessToken);
        // Fetch all saved videos from playlists
        allContent = await fetchAllYouTubeContent(service, userId);
        break;
        
      case 'instagram':
        service = new InstagramService(accessToken);
        // Fetch all saved posts/reels
        allContent = await fetchAllInstagramContent(service, userId);
        break;
        
      case 'facebook':
        service = new FacebookService(accessToken);
        // Fetch all saved posts
        allContent = await fetchAllFacebookContent(service, userId);
        break;
        
      default:
        throw new Error(`Unknown platform: ${platform}`);
    }
    
    console.log(`[Background Sync] Fetched ${allContent.length} items from ${platform} for user ${userId}`);
    
    // Index all content in Firestore with embeddings
    const syncResult = await syncPlatformContent(userId, platform, allContent);
    
    console.log(`[Background Sync] Indexed ${syncResult.indexed} items from ${platform} for user ${userId}`);
    
    return {
      success: true,
      platform: platform,
      itemsFetched: allContent.length,
      itemsIndexed: syncResult.indexed || 0,
      message: `Synced ${syncResult.indexed} items from ${platform}`
    };
    
  } catch (error) {
    console.error(`Error syncing ${platform}:`, error);
    return {
      success: false,
      platform: platform,
      error: error.message
    };
  }
}

/**
 * Fetch ALL YouTube saved content
 */
async function fetchAllYouTubeContent(service, userId) {
  const allContent = [];
  
  try {
    if (!service.accessToken) {
      console.warn('No YouTube access token, cannot fetch saved content');
      return [];
    }
    
    const { google } = require('googleapis');
    const oauth2Client = new google.auth.OAuth2();
    oauth2Client.setCredentials({ access_token: service.accessToken });
    const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
    
    // Get all playlists (saved videos)
    let nextPageToken = null;
    do {
      const playlistsResponse = await youtube.playlists.list({
        part: 'snippet,contentDetails',
        mine: true,
        maxResults: 50,
        pageToken: nextPageToken
      });
      
      const playlists = playlistsResponse.data.items || [];
      
      // For each playlist, get all items
      for (const playlist of playlists) {
        let itemsPageToken = null;
        do {
          try {
            const itemsResponse = await youtube.playlistItems.list({
              part: 'snippet,contentDetails',
              playlistId: playlist.id,
              maxResults: 50,
              pageToken: itemsPageToken
            });
            
            const items = itemsResponse.data.items || [];
            
            for (const item of items) {
              allContent.push({
                platform: 'YouTube',
                id: item.snippet.resourceId.videoId,
                title: item.snippet.title,
                description: item.snippet.description || '',
                thumbnail: item.snippet.thumbnails?.medium?.url || item.snippet.thumbnails?.default?.url,
                url: `https://www.youtube.com/watch?v=${item.snippet.resourceId.videoId}`,
                channel: item.snippet.channelTitle,
                publishedAt: item.snippet.publishedAt,
                type: 'video',
                savedIn: playlist.snippet.title,
                savedAt: item.snippet.publishedAt
              });
            }
            
            itemsPageToken = itemsResponse.data.nextPageToken;
          } catch (err) {
            console.error(`Error fetching playlist items for ${playlist.id}:`, err);
            break;
          }
        } while (itemsPageToken);
      }
      
      nextPageToken = playlistsResponse.data.nextPageToken;
    } while (nextPageToken);
    
    // Also get liked videos
    try {
      let likedPageToken = null;
      do {
        const likedResponse = await youtube.videos.list({
          part: 'snippet,contentDetails',
          myRating: 'like',
          maxResults: 50,
          pageToken: likedPageToken
        });
        
        const likedVideos = likedResponse.data.items || [];
        for (const video of likedVideos) {
          allContent.push({
            platform: 'YouTube',
            id: video.id,
            title: video.snippet.title,
            description: video.snippet.description || '',
            thumbnail: video.snippet.thumbnails?.medium?.url || video.snippet.thumbnails?.default?.url,
            url: `https://www.youtube.com/watch?v=${video.id}`,
            channel: video.snippet.channelTitle,
            publishedAt: video.snippet.publishedAt,
            type: 'video',
            savedIn: 'Liked Videos',
            savedAt: video.snippet.publishedAt
          });
        }
        
        likedPageToken = likedResponse.data.nextPageToken;
      } while (likedPageToken);
    } catch (err) {
      console.error('Error fetching liked videos:', err);
    }
    
  } catch (error) {
    console.error('Error fetching YouTube content:', error);
  }
  
  return allContent;
}

/**
 * Fetch ALL Instagram saved content
 */
async function fetchAllInstagramContent(service, userId) {
  const allContent = [];
  
  try {
    if (!service.accessToken) {
      console.warn('No Instagram access token, cannot fetch saved content');
      return [];
    }
    
    const axios = require('axios');
    let nextUrl = `${service.baseUrl}/me/saved`;
    let pageCount = 0;
    const maxPages = 100; // Limit to prevent infinite loops
    
    while (nextUrl && pageCount < maxPages) {
      try {
        const response = await axios.get(nextUrl, {
          params: {
            access_token: service.accessToken,
            fields: 'id,caption,media_type,media_url,thumbnail_url,permalink,timestamp',
            limit: 25
          }
        });
        
        const items = response.data.data || [];
        
        for (const item of items) {
          allContent.push({
            platform: 'Instagram',
            id: item.id,
            caption: item.caption || '',
            mediaType: item.media_type,
            mediaUrl: item.media_url,
            thumbnail: item.thumbnail_url || item.media_url,
            url: item.permalink,
            timestamp: item.timestamp,
            type: item.media_type === 'VIDEO' ? 'reel' : 'post',
            savedAt: item.timestamp
          });
        }
        
        nextUrl = response.data.paging?.next || null;
        pageCount++;
        
        // Rate limiting - small delay
        if (nextUrl) {
          await new Promise(resolve => setTimeout(resolve, 500));
        }
      } catch (err) {
        console.error('Error fetching Instagram page:', err);
        break;
      }
    }
    
  } catch (error) {
    console.error('Error fetching Instagram content:', error);
  }
  
  return allContent;
}

/**
 * Fetch ALL Facebook saved content
 */
async function fetchAllFacebookContent(service, userId) {
  const allContent = [];
  
  try {
    if (!service.accessToken) {
      console.warn('No Facebook access token, cannot fetch saved content');
      return [];
    }
    
    const axios = require('axios');
    let nextUrl = `${service.baseUrl}/me/saved`;
    let pageCount = 0;
    const maxPages = 100; // Limit to prevent infinite loops
    
    while (nextUrl && pageCount < maxPages) {
      try {
        const response = await axios.get(nextUrl, {
          params: {
            access_token: service.accessToken,
            fields: 'id,message,story,created_time,permalink_url,attachments{media,subattachments}',
            limit: 25
          }
        });
        
        const items = response.data.data || [];
        
        for (const item of items) {
          const mediaUrl = item.attachments?.data?.[0]?.media?.image?.src || 
                          item.attachments?.data?.[0]?.subattachments?.data?.[0]?.media?.image?.src;
          
          allContent.push({
            platform: 'Facebook',
            id: item.id,
            message: item.message || item.story || '',
            mediaUrl: mediaUrl,
            url: item.permalink_url,
            timestamp: item.created_time,
            type: 'post',
            savedAt: item.created_time
          });
        }
        
        nextUrl = response.data.paging?.next || null;
        pageCount++;
        
        // Rate limiting - small delay
        if (nextUrl) {
          await new Promise(resolve => setTimeout(resolve, 500));
        }
      } catch (err) {
        console.error('Error fetching Facebook page:', err);
        break;
      }
    }
    
  } catch (error) {
    console.error('Error fetching Facebook content:', error);
  }
  
  return allContent;
}

/**
 * Sync all platforms for a user
 */
async function syncAllPlatformsForUser(userId, userTokens) {
  const results = [];
  
  if (userTokens.youtube) {
    const youtubeResult = await syncAllPlatformContent(userId, 'youtube', userTokens.youtube);
    results.push(youtubeResult);
  }
  
  if (userTokens.instagram) {
    const instagramResult = await syncAllPlatformContent(userId, 'instagram', userTokens.instagram);
    results.push(instagramResult);
  }
  
  if (userTokens.facebook) {
    const facebookResult = await syncAllPlatformContent(userId, 'facebook', userTokens.facebook);
    results.push(facebookResult);
  }
  
  return results;
}

module.exports = {
  syncAllPlatformContent,
  syncAllPlatformsForUser,
  fetchAllYouTubeContent,
  fetchAllInstagramContent,
  fetchAllFacebookContent
};

