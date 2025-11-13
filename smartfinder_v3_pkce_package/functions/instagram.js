
const axios = require('axios');

async function getUserMedia(access_token) {
  const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${access_token}`;
  const resp = await axios.get(url);
  return resp.data.data || [];
}

exports.fetchReels = async (req, res, data) => {
  try {
    const { ig_access } = req.body;
    if(!ig_access) return res.status(400).json({ error: 'No instagram access_token provided' });
    const media = await getUserMedia(ig_access);
    const reels = media.filter(m => m.media_type === 'VIDEO' || (m.media_type==='IMAGE' && m.thumbnail_url)).map(m => ({
      id: m.id, caption: m.caption, media_url: m.media_url, permalink: m.permalink, media_type: m.media_type
    }));
    res.json({ reply: data.reply, reels });
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).json({ error: e.message });
  }
};
