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
const { logSync, logError } = require('./debugLogger');

async function syncAllPlatformContent(userId, platform, accessToken) {
  try {
    console.log(`[Background Sync] Starting full sync for ${platform} for user ${userId}`);
    await logSync(platform, userId, 'started', { accessTokenPresent: !!accessToken });
    
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
    
    // Log what was fetched (for debugging)
    if (allContent.length === 0) {
      console.log(`[Background Sync] WARNING: No content fetched from ${platform}. User may have no saved content, or API call failed.`);
      await logSync(platform, userId, 'completed', {
        itemsFetched: 0,
        itemsIndexed: 0,
        warning: 'No content found - user may have no saved content on this platform'
      });
    }
    
    // Index all content in Firestore with embeddings
    const syncResult = await syncPlatformContent(userId, platform, allContent);
    
    console.log(`[Background Sync] Indexed ${syncResult.indexed} items from ${platform} for user ${userId}`);
    console.log(`[Background Sync] Summary: Fetched ${allContent.length} items, Indexed ${syncResult.indexed} items`);
    
    // Log sync completion with detailed info
    await logSync(platform, userId, 'completed', {
      itemsFetched: allContent.length,
      itemsIndexed: syncResult.indexed || 0,
      fetchSuccess: allContent.length > 0,
      indexSuccess: syncResult.success !== false
    });
    
    return {
      success: true,
      platform: platform,
      itemsFetched: allContent.length,
      itemsIndexed: syncResult.indexed || 0,
      message: `Synced ${syncResult.indexed} items from ${platform}`,
      syncedAt: new Date().toISOString()
    };
    
  } catch (error) {
    console.error(`Error syncing ${platform}:`, error);
    await logError(error, { platform, userId }, userId);
    await logSync(platform, userId, 'failed', { error: error.message });
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
      console.warn('[YouTube Sync] No YouTube access token, cannot fetch saved content');
      await logSync('youtube', userId, 'failed', { error: 'No access token' });
      return [];
    }
    
    console.log(`[YouTube Sync] Starting fetch for user ${userId}`);
    console.log(`[YouTube Sync] Access token present: ${!!service.accessToken}, length: ${service.accessToken?.length || 0}`);
    
    const { google } = require('googleapis');
    const oauth2Client = new google.auth.OAuth2();
    oauth2Client.setCredentials({ access_token: service.accessToken });
    const youtube = google.youtube({ version: 'v3', auth: oauth2Client });
    
    // Test API access first
    try {
      const testResponse = await youtube.channels.list({
        part: 'snippet',
        mine: true,
        maxResults: 1
      });
      console.log(`[YouTube Sync] API access test successful. Channel: ${testResponse.data.items?.[0]?.snippet?.title || 'Unknown'}`);
    } catch (testErr) {
      console.error(`[YouTube Sync] API access test FAILED: ${testErr.message}`);
      console.error(`[YouTube Sync] Error details:`, testErr.response?.data || testErr);
      
      // Check if it's an authentication error
      const isAuthError = testErr.message?.includes('Invalid Credentials') || 
                         testErr.message?.includes('UNAUTHENTICATED') ||
                         testErr.response?.status === 401;
      
      if (isAuthError) {
        const errorMsg = 'OAuth token expired or invalid. Please reconnect YouTube to get a fresh token.';
        console.error(`[YouTube Sync] ${errorMsg}`);
        await logSync('youtube', userId, 'failed', { 
          error: errorMsg,
          errorType: 'authentication',
          requiresReconnect: true,
          details: testErr.response?.data 
        });
        throw new Error(errorMsg);
      }
      
      await logSync('youtube', userId, 'failed', { 
        error: `API access test failed: ${testErr.message}`,
        details: testErr.response?.data 
      });
      throw new Error(`YouTube API access failed: ${testErr.message}`);
    }
    
    // Get all playlists (saved videos)
    let playlistCount = 0;
    let nextPageToken = null;
    do {
      const playlistsResponse = await youtube.playlists.list({
        part: 'snippet,contentDetails',
        mine: true,
        maxResults: 50,
        pageToken: nextPageToken
      });
      
      const playlists = playlistsResponse.data.items || [];
      playlistCount += playlists.length;
      console.log(`[YouTube Sync] Found ${playlists.length} playlists (total so far: ${playlistCount})`);
      
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
            console.log(`[YouTube Sync] Fetched ${items.length} items from playlist "${playlist.snippet.title}"`);
          } catch (err) {
            console.error(`[YouTube Sync] Error fetching playlist items for ${playlist.id} (${playlist.snippet.title}):`, err.message);
            console.error(`[YouTube Sync] Error details:`, err.response?.data || err);
            await logSync('youtube', userId, 'failed', { 
              error: `Playlist fetch error: ${err.message}`,
              playlistId: playlist.id,
              playlistName: playlist.snippet.title,
              errorDetails: err.response?.data 
            });
            // Continue with other playlists instead of breaking
            break;
          }
        } while (itemsPageToken);
      }
      
      nextPageToken = playlistsResponse.data.nextPageToken;
    } while (nextPageToken);
    
    console.log(`[YouTube Sync] Total playlists processed: ${playlistCount}, Total items from playlists: ${allContent.length}`);
    
    // Get Watch Later playlist (special playlist with ID 'WL')
    try {
      let wlPageToken = null;
      let wlCount = 0;
      do {
        const wlResponse = await youtube.playlistItems.list({
          part: 'snippet,contentDetails',
          playlistId: 'WL', // Watch Later is a special playlist
          maxResults: 50,
          pageToken: wlPageToken
        });
        
        const wlItems = wlResponse.data.items || [];
        wlCount += wlItems.length;
        console.log(`[YouTube Sync] Fetched ${wlItems.length} items from Watch Later (total so far: ${wlCount})`);
        
        for (const item of wlItems) {
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
            savedIn: 'Watch Later',
            savedAt: item.snippet.publishedAt
          });
        }
        
        wlPageToken = wlResponse.data.nextPageToken;
      } while (wlPageToken);
      console.log(`[YouTube Sync] Total Watch Later items: ${wlCount}`);
    } catch (err) {
      console.error('[YouTube Sync] Error fetching Watch Later:', err.message);
      // Don't fail entire sync if Watch Later fails - it might not exist for user
      if (err.response?.status !== 404) {
        await logSync('youtube', userId, 'failed', { 
          error: `Watch Later fetch error: ${err.message}` 
        });
      }
    }
    
    // Also get liked videos
    try {
      let likedCount = 0;
      let likedPageToken = null;
      do {
        const likedResponse = await youtube.videos.list({
          part: 'snippet,contentDetails',
          myRating: 'like',
          maxResults: 50,
          pageToken: likedPageToken
        });
        
        const likedVideos = likedResponse.data.items || [];
        likedCount += likedVideos.length;
        console.log(`[YouTube Sync] Fetched ${likedVideos.length} liked videos (total so far: ${likedCount})`);
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
      console.log(`[YouTube Sync] Total liked videos: ${likedCount}`);
    } catch (err) {
      console.error('[YouTube Sync] Error fetching liked videos:', err.message);
      console.error('[YouTube Sync] Error details:', err.response?.data || err);
      await logSync('youtube', userId, 'failed', { 
        error: `Liked videos fetch error: ${err.message}`,
        errorDetails: err.response?.data,
        errorCode: err.code
      });
    }
    
    // Calculate breakdown
    const playlistItems = allContent.filter(c => c.savedIn !== 'Liked Videos' && c.savedIn !== 'Watch Later').length;
    const watchLaterItems = allContent.filter(c => c.savedIn === 'Watch Later').length;
    
    console.log(`[YouTube Sync] COMPLETE: Total items fetched: ${allContent.length}`);
    console.log(`[YouTube Sync] Breakdown: ${playlistItems} from playlists, ${watchLaterItems} from Watch Later, ${likedCount} liked videos`);
    
  } catch (error) {
    console.error('[YouTube Sync] Error fetching YouTube content:', error.message);
    await logSync('youtube', userId, 'failed', { 
      error: `Fetch error: ${error.message}`,
      stack: error.stack 
    });
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

