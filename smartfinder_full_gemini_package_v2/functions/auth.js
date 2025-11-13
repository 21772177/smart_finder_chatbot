
const express = require('express');
const axios = require('axios');
const router = express.Router();

// Helper to build redirect URIs
const oauthBase = process.env.OAUTH_REDIRECT_BASE || '';

// --- Google OAuth (already present) ---
router.get('/google', (req, res) => {
  const client_id = process.env.GOOGLE_OAUTH_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/google/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/maps.timeline.readonly https://www.googleapis.com/auth/userinfo.email openid');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&access_type=offline&prompt=consent`;
  res.redirect(url);
});

router.get('/google/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const redirect_uri = `${oauthBase}/auth/google/callback`;
    const params = new URLSearchParams();
    params.append('code', code);
    params.append('client_id', process.env.GOOGLE_OAUTH_CLIENT_ID);
    params.append('client_secret', process.env.GOOGLE_OAUTH_CLIENT_SECRET);
    params.append('redirect_uri', redirect_uri);
    params.append('grant_type', 'authorization_code');
    const tokenResp = await axios.post('https://oauth2.googleapis.com/token', params);
    const tokens = tokenResp.data;
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'google', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>Google connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) { res.status(500).send('Google OAuth error'); }
});

// --- Instagram OAuth (Basic Display / Graph fallback) ---
// Note: Instagram Basic Display does not provide 'likes' or 'saved' access for personal accounts.
// Business/Creator Instagram accounts via Graph API have more access (requires App Review).
// We'll implement the OAuth flow that returns a user access token to the client.
router.get('/instagram', (req, res) => {
  const client_id = process.env.INSTAGRAM_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/instagram/callback`;
  const scope = encodeURIComponent('user_profile,user_media');
  const url = `https://api.instagram.com/oauth/authorize?client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&response_type=code`;
  res.redirect(url);
});

router.get('/instagram/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const redirect_uri = `${oauthBase}/auth/instagram/callback`;
    const params = new URLSearchParams();
    params.append('client_id', process.env.INSTAGRAM_CLIENT_ID);
    params.append('client_secret', process.env.INSTAGRAM_CLIENT_SECRET);
    params.append('grant_type', 'authorization_code');
    params.append('redirect_uri', redirect_uri);
    params.append('code', code);
    // Exchange code for short-lived token (Basic Display)
    const tokenResp = await axios.post('https://api.instagram.com/oauth/access_token', params);
    const tokens = tokenResp.data; // contains access_token, user_id (short-lived)
    // For Graph API long-lived token exchange, additional steps are needed (server-side)
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'instagram', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>Instagram connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) { console.error(e.response && e.response.data); res.status(500).send('Instagram OAuth error'); }
});

// --- YouTube OAuth ---
router.get('/youtube', (req, res) => {
  const client_id = process.env.YT_OAUTH_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/youtube/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/youtube.readonly');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&access_type=offline&prompt=consent`;
  res.redirect(url);
});

router.get('/youtube/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const redirect_uri = `${oauthBase}/auth/youtube/callback`;
    const params = new URLSearchParams();
    params.append('code', code);
    params.append('client_id', process.env.YT_OAUTH_CLIENT_ID);
    params.append('client_secret', process.env.YT_OAUTH_CLIENT_SECRET);
    params.append('redirect_uri', redirect_uri);
    params.append('grant_type', 'authorization_code');
    const tokenResp = await axios.post('https://oauth2.googleapis.com/token', params);
    const tokens = tokenResp.data;
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'youtube', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>YouTube connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) { console.error(e.response && e.response.data); res.status(500).send('YouTube OAuth error'); }
});

module.exports.oauthRoutes = router;
