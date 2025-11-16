const axios = require('axios');
const API_KEY = process.env.YT_API_KEY || '';
async function searchPublic(q) {
  const url = `https://www.googleapis.com/youtube/v3/search?part=snippet&q=${encodeURIComponent(q)}&type=video&maxResults=6&key=${API_KEY}`;
  const r = await axios.get(url);
  return r.data.items.map(i=>({ title:i.snippet.title, channel:i.snippet.channelTitle, videoId:i.id.videoId, url:`https://www.youtube.com/watch?v=${i.id.videoId}`}));
}
async function fetchLiked(access_token) {
  const url = 'https://www.googleapis.com/youtube/v3/videos?part=snippet&myRating=like&maxResults=50';
  const r = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
  return r.data.items || [];
}
async function run(input) {
  const { query, access_token, user_mode } = input || {};
  if(user_mode === 'likes' && access_token) {
    const items = await fetchLiked(access_token);
    return items.map(i=>({ title:i.snippet.title, channel:i.snippet.channelTitle, url:`https://www.youtube.com/watch?v=${i.id}`}));
  }
  if(user_mode === 'watchlater' && access_token) {
    const url = `https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=WL&maxResults=50`;
    const r = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
    return (r.data.items||[]).map(i=>({ title:i.snippet.title, channel:i.snippet.channelTitle, url:`https://www.youtube.com/watch?v=${i.snippet.resourceId.videoId}`}));
  }
  return await searchPublic(query || 'trending');
}
module.exports = { run };
