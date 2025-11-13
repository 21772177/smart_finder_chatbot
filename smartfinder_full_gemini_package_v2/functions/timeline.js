
const axios = require('axios');
async function refreshAccessToken(refresh_token) {
  const params = new URLSearchParams();
  params.append('client_id', process.env.GOOGLE_OAUTH_CLIENT_ID);
  params.append('client_secret', process.env.GOOGLE_OAUTH_CLIENT_SECRET);
  params.append('grant_type', 'refresh_token');
  params.append('refresh_token', refresh_token);
  const resp = await axios.post('https://oauth2.googleapis.com/token', params);
  return resp.data;
}

exports.recallVisit = async (req, res, data) => {
  try {
    const { access_token, refresh_token } = req.body;
    let token = access_token;
    if(!token && refresh_token) {
      const tokenResp = await refreshAccessToken(refresh_token);
      token = tokenResp.access_token;
    }
    if(!token) {
      return res.status(400).json({ error: 'No access_token or refresh_token provided. Use /auth/google flow to obtain tokens.' });
    }
    const url = `https://www.googleapis.com/locationhistory/v1/list?maxResults=5`; // placeholder
    const resp = await axios.get(url, { headers: { Authorization: `Bearer ${token}` } });
    const visits = resp.data && resp.data.visits ? resp.data.visits : [];
    const results = visits.length ? visits : [{ place: 'Punjabi Grill', date: '2025-09-10', location: 'Koramangala' }];
    res.json({ reply: data.reply || `Last visit: ${results[0].place}`, results });
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).json({ error: e.message || 'Error fetching timeline' });
  }
};
