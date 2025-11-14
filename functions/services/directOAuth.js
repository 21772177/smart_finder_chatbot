/**
 * Direct OAuth Routes (from Gemini v2 package)
 * Provides simple popup-based OAuth flows for Google, Instagram, YouTube
 * Tokens are returned to client via postMessage
 */

const express = require('express');
const axios = require('axios');
const functions = require('firebase-functions');

const router = express.Router();

// Helper to build redirect URIs
function getOAuthBase() {
  if (process.env.OAUTH_REDIRECT_BASE) {
    return process.env.OAUTH_REDIRECT_BASE;
  }
  if (typeof functions !== 'undefined' && functions.config().oauth?.redirect_base) {
    return functions.config().oauth.redirect_base;
  }
  // Default to current Firebase hosting URL
  return 'https://buildkit-1695f.web.app';
}

// Helper to create error HTML
function sendError(res, message) {
  res.status(400).send(`<html><body><h3>Auth error: ${message}</h3></body></html>`);
}

// --- Google OAuth ---
router.get('/google', (req, res) => {
  const client_id = process.env.GOOGLE_OAUTH_CLIENT_ID || 
    (typeof functions !== 'undefined' && functions.config().google?.client_id);
  
  if (!client_id) {
    return sendError(res, 'Google OAuth client_id not configured');
  }
  
  const oauthBase = getOAuthBase();
  const redirect_uri = `${oauthBase}/auth/google/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/maps.timeline.readonly https://www.googleapis.com/auth/userinfo.email openid');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${encodeURIComponent(redirect_uri)}&scope=${scope}&access_type=offline&prompt=consent`;
  res.redirect(url);
});

router.get('/google/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const oauthBase = getOAuthBase();
    const redirect_uri = `${oauthBase}/auth/google/callback`;
    const client_id = process.env.GOOGLE_OAUTH_CLIENT_ID || 
      (typeof functions !== 'undefined' && functions.config().google?.client_id);
    const client_secret = process.env.GOOGLE_OAUTH_CLIENT_SECRET || 
      (typeof functions !== 'undefined' && functions.config().google?.client_secret);
    
    if (!client_id || !client_secret) {
      return sendError(res, 'Google OAuth credentials not configured');
    }
    
    const params = new URLSearchParams();
    params.append('code', code);
    params.append('client_id', client_id);
    params.append('client_secret', client_secret);
    params.append('redirect_uri', redirect_uri);
    params.append('grant_type', 'authorization_code');
    
    const tokenResp = await axios.post('https://oauth2.googleapis.com/token', params);
    const tokens = tokenResp.data;
    
    // Auto-sync in background if we can identify user (optional enhancement)
    // For now, tokens are returned to client
    
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'google', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>Google connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) {
    console.error('Google OAuth error:', e.response?.data || e.message);
    res.status(500).send('Google OAuth error');
  }
});

// --- Instagram OAuth ---
router.get('/instagram', (req, res) => {
  const client_id = process.env.INSTAGRAM_CLIENT_ID || 
    (typeof functions !== 'undefined' && functions.config().instagram?.client_id);
  
  if (!client_id) {
    return sendError(res, 'Instagram OAuth client_id not configured');
  }
  
  const oauthBase = getOAuthBase();
  const redirect_uri = `${oauthBase}/auth/instagram/callback`;
  const scope = encodeURIComponent('user_profile,user_media');
  const url = `https://api.instagram.com/oauth/authorize?client_id=${client_id}&redirect_uri=${encodeURIComponent(redirect_uri)}&scope=${scope}&response_type=code`;
  res.redirect(url);
});

router.get('/instagram/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const oauthBase = getOAuthBase();
    const redirect_uri = `${oauthBase}/auth/instagram/callback`;
    const client_id = process.env.INSTAGRAM_CLIENT_ID || 
      (typeof functions !== 'undefined' && functions.config().instagram?.client_id);
    const client_secret = process.env.INSTAGRAM_CLIENT_SECRET || 
      (typeof functions !== 'undefined' && functions.config().instagram?.client_secret);
    
    if (!client_id || !client_secret) {
      return sendError(res, 'Instagram OAuth credentials not configured');
    }
    
    const params = new URLSearchParams();
    params.append('client_id', client_id);
    params.append('client_secret', client_secret);
    params.append('grant_type', 'authorization_code');
    params.append('redirect_uri', redirect_uri);
    params.append('code', code);
    
    const tokenResp = await axios.post('https://api.instagram.com/oauth/access_token', params);
    const tokens = tokenResp.data;
    
    // Auto-sync in background if we can identify user (optional enhancement)
    // For now, tokens are returned to client
    
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'instagram', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>Instagram connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) {
    console.error('Instagram OAuth error:', e.response?.data || e.message);
    res.status(500).send('Instagram OAuth error');
  }
});

// --- YouTube OAuth ---
router.get('/youtube', (req, res) => {
  const client_id = process.env.YT_OAUTH_CLIENT_ID || 
    process.env.YOUTUBE_CLIENT_ID ||
    (typeof functions !== 'undefined' && functions.config().youtube?.client_id);
  
  if (!client_id) {
    return sendError(res, 'YouTube OAuth client_id not configured');
  }
  
  const oauthBase = getOAuthBase();
  const redirect_uri = `${oauthBase}/auth/youtube/callback`;
  const scope = encodeURIComponent('https://www.googleapis.com/auth/youtube.readonly');
  const url = `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${client_id}&redirect_uri=${encodeURIComponent(redirect_uri)}&scope=${scope}&access_type=offline&prompt=consent`;
  res.redirect(url);
});

router.get('/youtube/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const oauthBase = getOAuthBase();
    const redirect_uri = `${oauthBase}/auth/youtube/callback`;
    const client_id = process.env.YT_OAUTH_CLIENT_ID || 
      process.env.YOUTUBE_CLIENT_ID ||
      (typeof functions !== 'undefined' && functions.config().youtube?.client_id);
    const client_secret = process.env.YT_OAUTH_CLIENT_SECRET || 
      process.env.YOUTUBE_CLIENT_SECRET ||
      (typeof functions !== 'undefined' && functions.config().youtube?.client_secret);
    
    if (!client_id || !client_secret) {
      return sendError(res, 'YouTube OAuth credentials not configured');
    }
    
    const params = new URLSearchParams();
    params.append('code', code);
    params.append('client_id', client_id);
    params.append('client_secret', client_secret);
    params.append('redirect_uri', redirect_uri);
    params.append('grant_type', 'authorization_code');
    
    const tokenResp = await axios.post('https://oauth2.googleapis.com/token', params);
    const tokens = tokenResp.data;
    
    // Auto-sync in background if we can identify user (optional enhancement)
    // For now, tokens are returned to client
    
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'youtube', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>YouTube connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) {
    console.error('YouTube OAuth error:', e.response?.data || e.message);
    res.status(500).send('YouTube OAuth error');
  }
});

// --- Facebook OAuth ---
router.get('/facebook', (req, res) => {
  const app_id = process.env.FACEBOOK_APP_ID || 
    (typeof functions !== 'undefined' && functions.config().facebook?.app_id);
  
  if (!app_id) {
    return sendError(res, 'Facebook OAuth app_id not configured');
  }
  
  const oauthBase = getOAuthBase();
  const redirect_uri = `${oauthBase}/auth/facebook/callback`;
  const scope = encodeURIComponent('user_posts,user_photos,user_videos');
  const url = `https://www.facebook.com/v18.0/dialog/oauth?client_id=${app_id}&redirect_uri=${encodeURIComponent(redirect_uri)}&scope=${scope}&response_type=code`;
  res.redirect(url);
});

router.get('/facebook/callback', async (req, res) => {
  try {
    const code = req.query.code;
    const oauthBase = getOAuthBase();
    const redirect_uri = `${oauthBase}/auth/facebook/callback`;
    const app_id = process.env.FACEBOOK_APP_ID || 
      (typeof functions !== 'undefined' && functions.config().facebook?.app_id);
    const app_secret = process.env.FACEBOOK_APP_SECRET || 
      (typeof functions !== 'undefined' && functions.config().facebook?.app_secret);
    
    if (!app_id || !app_secret) {
      return sendError(res, 'Facebook OAuth credentials not configured');
    }
    
    // Exchange code for access token
    const tokenUrl = `https://graph.facebook.com/v18.0/oauth/access_token?client_id=${app_id}&client_secret=${app_secret}&redirect_uri=${encodeURIComponent(redirect_uri)}&code=${code}`;
    const tokenResp = await axios.get(tokenUrl);
    const tokens = tokenResp.data;
    
    const html = `<html><body><script>window.opener.postMessage({type:'smartfinder_tokens', provider:'facebook', tokens:${JSON.stringify(tokens)}}, '*');document.body.innerHTML='<h3>Facebook connected. Close this window.</h3>';</script></body></html>`;
    res.send(html);
  } catch (e) {
    console.error('Facebook OAuth error:', e.response?.data || e.message);
    res.status(500).send('Facebook OAuth error');
  }
});

module.exports = { directOAuthRoutes: router };

