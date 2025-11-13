/**
 * Direct Fetch Handlers (from Gemini v2 package)
 * Handles direct API calls with access tokens from client
 */

const axios = require('axios');
const functions = require('firebase-functions');

/**
 * Fetch places (Google Places API)
 */
async function fetchPlacesDirect(req, res, data, location) {
  try {
    const locationStr = data.location || (location && `${location.lat},${location.lng}`) || "nearby";
    const type = data.type || "restaurant";
    const apiKey = process.env.GOOGLE_MAPS_KEY || 
      (typeof functions !== 'undefined' && functions.config().google?.maps_key);
    
    if (!apiKey) {
      return res.status(400).json({ error: 'Google Maps API key not configured' });
    }
    
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${encodeURIComponent(type + ' in ' + locationStr)}&key=${apiKey}`;
    const response = await axios.get(url);
    
    const results = (response.data.results || []).slice(0, 6).map(p => ({
      name: p.name,
      address: p.formatted_address,
      rating: p.rating,
      place_id: p.place_id,
      maps_url: `https://www.google.com/maps/place/?q=place_id:${p.place_id}`,
      photo_reference: p.photos && p.photos.length ? p.photos[0].photo_reference : null,
      photo_url: p.photos && p.photos.length ? 
        `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${p.photos[0].photo_reference}&key=${apiKey}` : null
    }));
    
    res.json({ 
      reply: data.reply || `Found ${results.length} ${type}${results.length !== 1 ? 's' : ''} near you`,
      results 
    });
  } catch (e) {
    console.error('Places fetch error:', e.response?.data || e.message);
    res.status(500).json({ error: e.message });
  }
}

/**
 * Recall visit (Google Timeline)
 */
async function recallVisitDirect(req, res, data, google_access) {
  try {
    if (!google_access) {
      return res.status(400).json({ 
        error: 'No Google access token provided. Connect Google account first.' 
      });
    }
    
    // Note: Google Timeline API requires special permissions and may not be publicly available
    // This is a placeholder implementation
    const url = `https://www.googleapis.com/locationhistory/v1/list?maxResults=5`;
    try {
      const resp = await axios.get(url, { 
        headers: { Authorization: `Bearer ${google_access}` } 
      });
      const visits = resp.data?.visits || [];
      const results = visits.length > 0 ? visits : [
        { place: 'Sample Location', date: new Date().toISOString().split('T')[0], location: 'Unknown' }
      ];
      res.json({ 
        reply: data.reply || `Last visit: ${results[0].place}`,
        results 
      });
    } catch (timelineError) {
      // Timeline API may not be available - return helpful message
      res.json({
        reply: 'Google Timeline API access requires additional permissions. This feature is being set up.',
        results: []
      });
    }
  } catch (e) {
    console.error('Timeline recall error:', e.response?.data || e.message);
    res.status(500).json({ error: e.message || 'Error fetching timeline' });
  }
}

/**
 * Fetch Instagram reels (direct with access token)
 */
async function fetchReelsDirect(access_token) {
  try {
    const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${access_token}`;
    const resp = await axios.get(url);
    return resp.data.data || [];
  } catch (e) {
    console.error('Instagram fetch error:', e.response?.data || e.message);
    return [];
  }
}

/**
 * Fetch YouTube liked videos and watch later (direct with access token)
 */
async function fetchYouTubeVideosDirect(access_token) {
  try {
    // Fetch liked videos
    const likedUrl = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&myRating=like';
    let liked = [];
    try {
      const likedResp = await axios.get(likedUrl, { 
        headers: { Authorization: `Bearer ${access_token}` } 
      });
      liked = likedResp.data.items || [];
    } catch (e) {
      console.warn('Error fetching liked videos:', e.message);
    }
    
    // Fetch watch later playlist
    const wlUrl = 'https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=WL&maxResults=50';
    let watchLater = [];
    try {
      const wlResp = await axios.get(wlUrl, { 
        headers: { Authorization: `Bearer ${access_token}` } 
      });
      watchLater = wlResp.data.items || [];
    } catch (e) {
      console.warn('Error fetching watch later:', e.message);
    }
    
    const mapItem = (i) => ({
      title: i.snippet.title,
      channel: i.snippet.channelTitle,
      url: `https://www.youtube.com/watch?v=${i.snippet.resourceId?.videoId || i.id?.videoId || ''}`
    });
    
    return {
      liked: liked.map(mapItem),
      watchLater: watchLater.map(mapItem)
    };
  } catch (e) {
    console.error('YouTube fetch error:', e.response?.data || e.message);
    return { liked: [], watchLater: [] };
  }
}

module.exports = {
  fetchPlacesDirect,
  recallVisitDirect,
  fetchReelsDirect,
  fetchYouTubeVideosDirect
};

