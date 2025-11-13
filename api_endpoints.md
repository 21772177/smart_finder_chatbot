API Endpoints - Smart Finder AI Chatbot (MVP)

Backend Endpoints (example)
1. POST /api/query
   - Body: { "query": "Find Goa reels", "location": { "lat": ..., "lng": ... }, "token": "<device-token>" }
   - Action: Parse intent, route to connectors, return aggregated results.
   - Response: { "session_id": "...", "results": [ ... ] }

2. GET /api/nearby?lat=...&lng=...&type=restaurant
   - Action: Query Google Places / Zomato, return top 10.

3. POST /api/recall
   - Body: { "token": "<device-token>", "location": { "lat", "lng" } }
   - Action: Use token + Maps Timeline to reconstruct last visit.

4. POST /api/social/fetch
   - Body: { "platform": "youtube|instagram", "oauth_token": "..." }
   - Action: Fetch saved or liked items via platform API (read-only).

5. POST /api/cleanup
   - Action: Clear server-side transient cache (if any).

Client-side logic:
 - Generate or read device token (localStorage).
 - Send query to /api/query with token and location.
 - Display results returned (cards with title, thumbnail, link).

Security:
 - Use OAuth 2.0 for platform-specific fetches.
 - Use HTTPS only.
 - Server must not persist oauth tokens beyond session; prefer storing in browser and passing ephemeral tokens to backend for live fetches.
