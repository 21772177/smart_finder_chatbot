
const axios = require('axios');

// Fetch user's liked videos (requires OAuth with youtube.readonly)
async function fetchLikedVideos(access_token) {
  // Using 'videos' list with myRating=like requires OAuth and special endpoint. We'll use playlist approach for demo.
  // Liked videos playlist id is 'LL' (legacy); better to call 'videos?myRating=like' with OAuth token.
  const url = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&myRating=like';
  const resp = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
  return resp.data.items || [];
}

// Fetch user's 'Watch Later' playlist items (playlistId='WL')
async function fetchWatchLater(access_token) {
  const url = `https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=WL&maxResults=50`;
  const resp = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
  return resp.data.items || [];
}

exports.fetchVideos = async (req, res, data) => {
  try {
    const { access_token } = req.body;
    if(access_token) {
      // If user provided token, fetch liked and watch-later lists
      const liked = await fetchLikedVideos(access_token);
      const wl = await fetchWatchLater(access_token);
      const mapItem = i => ({ title: i.snippet.title, channel: i.snippet.channelTitle, url: `https://www.youtube.com/watch?v=${i.snippet.resourceId ? i.snippet.resourceId.videoId : (i.id && i.id.videoId) || ''}` });
      const videos = liked.map(mapItem).concat(wl.map(mapItem));
      return res.json({ reply: data.reply, videos });
    } else {
      // Public search fallback
      const q = encodeURIComponent(`${data.location || ""} ${data.type || ""}`);
      const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${q}&type=video&maxResults=5&key=${process.env.YT_API_KEY}`;
      const response = await axios.get(url);
      const videos = response.data.items.map(v => ({
        title: v.snippet.title,
        channel: v.snippet.channelTitle,
        videoId: v.id.videoId,
        url: `https://www.youtube.com/watch?v=${v.id.videoId}`
      }));
      res.json({ reply: data.reply, videos });
    }
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).json({ error: e.message });
  }
};
