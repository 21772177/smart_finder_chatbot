
const axios = require('axios');

async function fetchLikedVideos(access_token) {
  const url = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&myRating=like';
  const resp = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
  return resp.data.items || [];
}

async function fetchWatchLater(access_token) {
  const url = `https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=WL&maxResults=50`;
  const resp = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
  return resp.data.items || [];
}

exports.fetchVideos = async (req, res, data) => {
  try {
    const { yt_access } = req.body;
    if(yt_access) {
      const liked = await fetchLikedVideos(yt_access);
      const wl = await fetchWatchLater(yt_access);
      const mapItem = i => ({ title: i.snippet.title, channel: i.snippet.channelTitle, url: `https://www.youtube.com/watch?v=${i.snippet.resourceId ? i.snippet.resourceId.videoId : (i.id && i.id.videoId) || ''}` });
      const videos = liked.map(mapItem).concat(wl.map(mapItem));
      return res.json({ reply: data.reply, videos });
    } else {
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
