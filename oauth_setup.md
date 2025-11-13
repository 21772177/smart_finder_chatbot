OAuth Setup (Google, YouTube, Instagram)

1) Google (Maps, Drive, Timeline)
 - Create project in Google Cloud Console
 - Enable APIs: Maps JavaScript API, Places API, Timeline API (Location History requires user-side permission)
 - Create OAuth consent screen (external) and OAuth client ID (web application)
 - In the chatbot, request scope: 'https://www.googleapis.com/auth/mapsengine.readonly' or appropriate timeline scopes
 - Use PKCE flow for web clients; do not persist refresh tokens on server

2) YouTube Data API
 - Enable YouTube Data API v3
 - Request scope: 'https://www.googleapis.com/auth/youtube.readonly'

3) Instagram / Meta Graph
 - Instagram personal saved posts are not available through public Graph API
 - Business/Creator accounts can access media via Graph API
 - Use Meta App Review if requesting advanced permissions

Security Notes:
 - Store tokens client-side in session/localStorage and pass ephemeral tokens to backend for live fetches
 - Revoke tokens on user sign-out
