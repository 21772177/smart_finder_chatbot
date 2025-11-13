/**
 * OAuth Handlers for Platform Connections
 * Handles OAuth flows for YouTube, Instagram, Facebook
 * Now includes PKCE support for enhanced security
 */

const { google } = require('googleapis');
const axios = require('axios');
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { verifyCodeChallenge } = require('./authManager');

/**
 * Generate YouTube OAuth URL (with PKCE support)
 */
function getYouTubeAuthUrl(redirectUri, codeChallenge = null, state = null) {
  const clientId = process.env.YT_OAUTH_CLIENT_ID || process.env.YOUTUBE_CLIENT_ID || (typeof functions !== 'undefined' && functions.config().youtube?.client_id);
  const clientSecret = process.env.YT_OAUTH_CLIENT_SECRET || process.env.YOUTUBE_CLIENT_SECRET || (typeof functions !== 'undefined' && functions.config().youtube?.client_secret);
  
  if (!clientId || !clientSecret) {
    throw new Error('YouTube OAuth credentials not configured. Please set youtube.client_id and youtube.client_secret in Firebase config.');
  }
  
  const scope = encodeURIComponent('https://www.googleapis.com/auth/youtube.readonly');
  const encodedState = encodeURIComponent(state || 'sf_' + Math.random().toString(36).slice(2));
  
  // PKCE flow
  if (codeChallenge) {
    return `https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scope}&access_type=offline&prompt=consent&state=${encodedState}&code_challenge=${encodeURIComponent(codeChallenge)}&code_challenge_method=S256`;
  }
  
  // Fallback to standard OAuth
  const oauth2Client = new google.auth.OAuth2(
    clientId,
    clientSecret,
    redirectUri
  );

  const scopes = [
    'https://www.googleapis.com/auth/youtube.readonly',
    'https://www.googleapis.com/auth/youtube.force-ssl'
  ];

  return oauth2Client.generateAuthUrl({
    access_type: 'offline',
    scope: scopes,
    prompt: 'consent',
    state: encodedState
  });
}

/**
 * Exchange YouTube OAuth code for token (with PKCE support)
 */
async function exchangeYouTubeCode(code, redirectUri, codeVerifier = null) {
  const clientId = process.env.YT_OAUTH_CLIENT_ID || process.env.YOUTUBE_CLIENT_ID || (typeof functions !== 'undefined' && functions.config().youtube?.client_id);
  const clientSecret = process.env.YT_OAUTH_CLIENT_SECRET || process.env.YOUTUBE_CLIENT_SECRET || (typeof functions !== 'undefined' && functions.config().youtube?.client_secret);
  
  const params = new URLSearchParams();
  params.append('code', code);
  params.append('client_id', clientId);
  params.append('client_secret', clientSecret);
  params.append('redirect_uri', redirectUri);
  params.append('grant_type', 'authorization_code');
  
  // Add PKCE verifier if provided
  if (codeVerifier) {
    params.append('code_verifier', codeVerifier);
  }
  
  const response = await axios.post('https://oauth2.googleapis.com/token', params);
  return response.data;
}

/**
 * Generate Instagram OAuth URL (with state support)
 */
function getInstagramAuthUrl(redirectUri, state = null) {
  const clientId = process.env.INSTAGRAM_CLIENT_ID || (typeof functions !== 'undefined' && functions.config().instagram?.client_id);
  
  if (!clientId) {
    throw new Error('Instagram OAuth credentials not configured. Please set instagram.client_id in Firebase config.');
  }
  
  const scopes = 'user_profile,user_media';
  const encodedState = state ? `&state=${encodeURIComponent(state)}` : '';
  
  return `https://api.instagram.com/oauth/authorize?client_id=${clientId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scopes}&response_type=code${encodedState}`;
}

/**
 * Exchange Instagram OAuth code for token
 */
async function exchangeInstagramCode(code, redirectUri) {
  const clientId = process.env.INSTAGRAM_CLIENT_ID || (typeof functions !== 'undefined' && functions.config().instagram?.client_id);
  const clientSecret = process.env.INSTAGRAM_CLIENT_SECRET || (typeof functions !== 'undefined' && functions.config().instagram?.client_secret);

  const response = await axios.post('https://api.instagram.com/oauth/access_token', {
    client_id: clientId,
    client_secret: clientSecret,
    grant_type: 'authorization_code',
    redirect_uri: redirectUri,
    code: code
  });

  return response.data;
}

/**
 * Generate Facebook OAuth URL (with state support)
 */
function getFacebookAuthUrl(redirectUri, state = null) {
  const appId = process.env.FACEBOOK_APP_ID || (typeof functions !== 'undefined' && functions.config().facebook?.app_id);
  
  if (!appId) {
    throw new Error('Facebook OAuth credentials not configured. Please set facebook.app_id in Firebase config.');
  }
  
  const scopes = 'user_posts,user_photos';
  const encodedState = state ? `&state=${encodeURIComponent(state)}` : '';
  
  return `https://www.facebook.com/v18.0/dialog/oauth?client_id=${appId}&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${scopes}&response_type=code${encodedState}`;
}

/**
 * Exchange Facebook OAuth code for token
 */
async function exchangeFacebookCode(code, redirectUri) {
  const appId = process.env.FACEBOOK_APP_ID || (typeof functions !== 'undefined' && functions.config().facebook?.app_id);
  const appSecret = process.env.FACEBOOK_APP_SECRET || (typeof functions !== 'undefined' && functions.config().facebook?.app_secret);

  const response = await axios.get('https://graph.facebook.com/v18.0/oauth/access_token', {
    params: {
      client_id: appId,
      client_secret: appSecret,
      redirect_uri: redirectUri,
      code: code
    }
  });

  return response.data;
}

module.exports = {
  getYouTubeAuthUrl,
  exchangeYouTubeCode,
  getInstagramAuthUrl,
  exchangeInstagramCode,
  getFacebookAuthUrl,
  exchangeFacebookCode
};

