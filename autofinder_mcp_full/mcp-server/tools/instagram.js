const axios = require('axios');
async function getUserMedia(access_token) {
  const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${access_token}`;
  const r = await axios.get(url);
  return r.data.data || [];
}
async function run(input) {
  const { access_token, filter } = input || {};
  if(!access_token) return { error: 'No access_token provided' };
  const media = await getUserMedia(access_token);
  const filtered = (media||[]).filter(m => !filter || (m.caption && m.caption.toLowerCase().includes(filter.toLowerCase())));
  return filtered.map(m=>({ id:m.id, caption:m.caption, media_type:m.media_type, url:m.media_url || m.thumbnail_url, permalink:m.permalink }));
}
module.exports = { run };
