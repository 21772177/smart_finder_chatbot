
const axios = require('axios');

// Helper: fetch user's media via Graph API using access_token
async function getUserMedia(access_token) {
  // Basic Graph API: /me/media returns media the user has on Instagram Basic Display
  const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${access_token}`;
  const resp = await axios.get(url);
  return resp.data.data || [];
}

// For Business/Creator accounts with Graph API, more fields and endpoints are available.
// Note: Instagram API does NOT provide 'saved' or 'liked' lists for personal accounts via Basic Display API.
// For Business accounts, you can read more advanced endpoints after app review.

exports.fetchReels = async (req, res, data) => {
  try {
    const { access_token } = req.body; // expected from client localStorage after OAuth
    if(!access_token) return res.status(400).json({ error: 'No instagram access_token provided' });
    const media = await getUserMedia(access_token);
    // Filter for reels/videos and optionally by location keywords in caption (best-effort)
    const reels = media.filter(m => m.media_type === 'VIDEO' || (m.media_type==='IMAGE' && m.thumbnail_url)).map(m => ({
      id: m.id,
      caption: m.caption,
      media_url: m.media_url,
      permalink: m.permalink,
      media_type: m.media_type
    }));
    // Return both 'media' as proxy for liked/saved (limited by API). Instruct user about API limits in README.
    res.json({ reply: data.reply, reels });
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).json({ error: e.message });
  }
};
