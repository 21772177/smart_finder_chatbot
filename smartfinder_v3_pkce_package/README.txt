
SmartFinder v3 - PKCE-enabled OAuth (prod) + dev legacy routes

What's included:
- PKCE flow for Google & YouTube (frontend generates code_verifier & code_challenge).
- Dev routes (google/dev, instagram/dev, youtube/dev) that skip PKCE for local testing.
- State parameter handling and sessionStorage-based verifier storage in frontend.
- Pop-up based OAuth where callback pages postMessage tokens back to the opener window.
- Tokens are stored in browser localStorage (client-side). Server does not persist user tokens.
- Verify PKCE server-side: authManager.verifyCodeChallenge helper included (useful if you want server-side verification steps).

Deployment notes:
1) Set environment variables using firebase functions:config:set or Secret Manager.
2) In production ensure NODE_ENV=production and DO NOT use /dev endpoints.
3) Install deps:
   cd functions
   npm install
4) Deploy:
   firebase deploy --only functions,hosting

Security notes:
- Always use HTTPS for OAUTH_REDIRECT_BASE and your hosted site.
- For production, validate postMessage origins and enforce short token lifetimes on client-side.
- After testing, remove /dev endpoints or ensure they are disabled in production via env checks.
