Tech Stack Recommendation

Frontend:
 - React + Tailwind CSS
 - Web Chat UI (socket or HTTP polling)
 - localForage or localStorage for device token

Backend:
 - Node.js + Express (or FastAPI in Python)
 - LangChain (optional) + OpenAI GPT-5 for NLU
 - Redis for transient cache (optional)

APIs:
 - Google Maps/Places/Timeline
 - YouTube Data API
 - Instagram Graph API (business endpoints)
 - Zomato / Local listing API

Hosting:
 - Vercel or Netlify for frontend
 - Render / AWS / GCP for backend (region: Mumbai preferred)
 - Use HTTPS, CORS configuration, and WAF if needed

Authentication:
 - OAuth 2.0 for Google/YouTube/Instagram
 - Device token stored in client (localStorage) for recall
