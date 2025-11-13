
const express = require('express');
const axios = require('axios');
const { verifyCodeChallenge } = require('./authManager');
const router = express.Router();

const oauthBase = process.env.OAUTH_REDIRECT_BASE || '';

// Helper to create error HTML
function sendError(res, message) {
  res.status(400).send(`<html><body><h3>Auth error: ${message}</h3></body></html>`);
}

/* ----------------------
   GOOGLE (PKCE + dev)
   ---------------------- */

// Production (PKCE) route
router.get('/google', (req, res) => {
  const client_id = process.env.GOOGLE_OAUTH_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/google/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/maps.timeline.readonly https://www.googleapis.com/auth/userinfo.email openid');
  const state = encodeURIComponent(req.query.state || 'sf_'+Math.random().toString(36).slice(2));
  const code_challenge = req.query.code_challenge; // expected from client (PKCE)
  if(!code_challenge) return sendError(res, 'Missing code_challenge (PKCE)');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&access_type=offline&prompt=consent&state=${state}&code_challenge=${code_challenge}&code_challenge_method=S256`;
  res.redirect(url);
});

// Dev (no PKCE) route - for local testing only
router.get('/google/dev', (req, res) => {
  const client_id = process.env.GOOGLE_OAUTH_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/google/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/maps.timeline.readonly https://www.googleapis.com/auth/userinfo.email openid');
  const state = encodeURIComponent(req.query.state || 'dev');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&access_type=offline&prompt=consent&state=${state}`;
  res.redirect(url);
});

// Callback (shared) - exchanges code for tokens, validates state minimally
router.get('/google/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const state = req.query.state;
    // If PKCE, client will have stored code_verifier in sessionStorage and will send it to client via postMessage.
    const redirect_uri = `${oauthBase}/auth/google/callback`;
    const params = new URLSearchParams();
    params.append('code', code);
    params.append('client_id', process.env.GOOGLE_OAUTH_CLIENT_ID);
    params.append('client_secret', process.env.GOOGLE_OAUTH_CLIENT_SECRET);
    params.append('redirect_uri', redirect_uri);
    params.append('grant_type', 'authorization_code');
    const tokenResp = await axios.post('https://oauth2.googleapis.com/token', params);
    const tokens = tokenResp.data;
    const html = `
      <html><body>
      <script>
        // send tokens to opener window (popup) securely
        const tokens = ${JSON.stringify(tokens)};
        if(window.opener && window.opener.postMessage) {
          window.opener.postMessage({ type:'smartfinder_tokens', provider:'google', tokens }, '*');
        }
        document.body.innerHTML = '<h3>Google connected. You can close this window.</h3>';
      </script>
      </body></html>`;
    res.send(html);
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).send('Google OAuth callback error');
  }
});

/* ----------------------
   INSTAGRAM (PKCE-like guidance; Basic Display doesn't support PKCE officially)
   ---------------------- */

// Production: require code_challenge param (frontend will provide) - best effort
router.get('/instagram', (req, res) => {
  const client_id = process.env.INSTAGRAM_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/instagram/callback`;
  const scope = encodeURIComponent('user_profile,user_media');
  const state = encodeURIComponent(req.query.state || 'sf_'+Math.random().toString(36).slice(2));
  // Instagram Basic Display does not officially support PKCE; we still accept a state and expect client to use short-lived token handling.
  const url = `https://api.instagram.com/oauth/authorize?client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&response_type=code&state=${state}`;
  res.redirect(url);
});

// Dev route (no PKCE/state stricter checks)
router.get('/instagram/dev', (req, res) => {
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
    const tokenResp = await axios.post('https://api.instagram.com/oauth/access_token', params);
    const tokens = tokenResp.data;
    const html = `
      <html><body>
      <script>
        const tokens = ${JSON.stringify(tokens)};
        if(window.opener && window.opener.postMessage) {
          window.opener.postMessage({ type:'smartfinder_tokens', provider:'instagram', tokens }, '*');
        }
        document.body.innerHTML = '<h3>Instagram connected. Close this window.</h3>';
      </script>
      </body></html>`;
    res.send(html);
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).send('Instagram OAuth error');
  }
});

/* ----------------------
   YOUTUBE (PKCE + dev)
   ---------------------- */

router.get('/youtube', (req, res) => {
  const client_id = process.env.YT_OAUTH_CLIENT_ID;
  const redirect_uri = `${oauthBase}/auth/youtube/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/youtube.readonly');
  const state = encodeURIComponent(req.query.state || 'sf_'+Math.random().toString(36).slice(2));
  const code_challenge = req.query.code_challenge;
  if(!code_challenge) return sendError(res, 'Missing code_challenge (PKCE)');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${redirect_uri}&scope=${scope}&access_type=offline&prompt=consent&state=${state}&code_challenge=${code_challenge}&code_challenge_method=S256`;
  res.redirect(url);
});

router.get('/youtube/dev', (req, res) => {
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
    const html = `
      <html><body>
      <script>
        const tokens = ${JSON.stringify(tokens)};
        if(window.opener && window.opener.postMessage) {
          window.opener.postMessage({ type:'smartfinder_tokens', provider:'youtube', tokens }, '*');
        }
        document.body.innerHTML = '<h3>YouTube connected. Close this window.</h3>';
      </script>
      </body></html>`;
    res.send(html);
  } catch (e) { console.error(e.response && e.response.data ? e.response.data : e.message); res.status(500).send('YouTube OAuth callback error'); }
});

module.exports.oauthRoutes = router;
