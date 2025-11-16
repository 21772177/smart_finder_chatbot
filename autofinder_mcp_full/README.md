AutoFinder MCP Full Architecture (Firebase + Gemini + Google Cloud Run)
------------------------------------------------------
Contents:
- mcp-server/           -> MCP server (tools) to deploy to Cloud Run
- firebase_functions/   -> Firebase Functions that call Gemini + MCP tools
- deployment/           -> cloudbuild.yaml template for Cloud Run deploy

Quick start (dev):
1) Deploy MCP locally:
   cd mcp-server
   npm install
   node server.js
2) Set env vars (example in mcp-server/config/env.example.json)
3) Run Firebase functions emulator or deploy to Firebase
4) Set MCP_URL env in Firebase to the Cloud Run URL when deployed

Security & notes:
- Store API keys in Secret Manager or Firebase functions config, not in code.
- Use HTTPS endpoints and validate origins when handling tokens.
- MCP tools contain placeholders for some marketplace connectors; replace with your own scrapers or APIs.
