SmartFinder Full Gemini Package v2 - Instagram & YouTube OAuth

This package adds:
- Instagram OAuth flow (/auth/instagram & callback) that returns short-lived token to client (popup).
- YouTube OAuth flow (/auth/youtube & callback) for user read-only access (likes, watch later).
- Frontend Connect buttons for Google, Instagram, YouTube.
- Fetch endpoints that accept `access_token` from client to read user-specific saved/liked media.

Important implementation notes & API limitations:
- Instagram Basic Display API does not provide 'saved' or 'liked' lists for personal accounts. For Business/Creator accounts, additional Graph API endpoints are available after app review. This package fetches user media and returns videos/images as a best-effort proxy for 'reels' and instructs in README how to upgrade permissions.
- YouTube: fetching liked videos and 'Watch Later' requires OAuth and correct scopes. This package attempts to read liked videos via the user's OAuth token; behavior may vary depending on API quotas and channel settings.
- Tokens are returned to the client (popup) and stored in localStorage. Server does not persist user tokens.
- Replace placeholder timeline endpoint in timeline.js with an approved Google Timeline method if available.

Deploy steps:
1. Set environment vars in Firebase functions config or secret manager.
2. Install dependencies and deploy:
   cd functions
   npm install
   firebase deploy --only functions,hosting
3. Use the hosted site, connect accounts, and test queries like "Show my Goa reels".

