# Building an updated ZIP with requested additions:
# - API layer (simple Express API in MCP server)
# - DB models (Firestore schema examples in firebase_functions/models)
# - Working MCP server skeleton (tool runner + session manager + scheduler)
# - Chrome extension logic (manifest v3, background, content, popup)
# - Auto-sync module (skeleton using Playwright placeholder and a scheduler)
# Package everything into /mnt/data/autofinder_mcp_updated.zip

from pathlib import Path
import zipfile, shutil, json, textwrap, os

base = Path("/mnt/data/autofinder_mcp_updated")
if base.exists():
    shutil.rmtree(base)
base.mkdir(parents=True, exist_ok=True)

# Create MCP server
mcp = base / "mcp-server"
tools = mcp / "tools"
config = mcp / "config"
utils = tools / "utils"
for p in [mcp, tools, config, utils]:
    p.mkdir(parents=True, exist_ok=True)

# package.json
pkg = {
  "name":"autofinder-mcp-updated",
  "version":"1.0.0",
  "main":"server.js",
  "engines":{"node":"18"},
  "dependencies":{
    "express":"^4.18.2",
    "axios":"^1.4.0",
    "body-parser":"^1.20.2",
    "cors":"^2.8.5",
    "node-cache":"^5.1.2",
    "playwright":"^1.40.0",
    "pino":"^8.0.0"
  }
}
(mcp / "package.json").write_text(json.dumps(pkg, indent=2))

# server.js (API layer + tool runner)
server_js = textwrap.dedent("""\
  const express = require('express');
  const bodyParser = require('body-parser');
  const cors = require('cors');
  const path = require('path');
  const fs = require('fs');
  const pino = require('pino')();
  const sessionManager = require('./sessionManager');
  const scheduler = require('./scheduler');

  const app = express();
  app.use(cors());
  app.use(bodyParser.json({ limit: '20mb' }));
  app.use((req,res,next)=>{ pino.info({msg:'incoming', path:req.path}); next(); });

  app.get('/health', (req,res)=> res.json({ status: 'ok' }));

  // API: list tools
  app.get('/api/tools', (req,res)=>{
    const toolsDir = path.join(__dirname,'tools');
    const files = fs.readdirSync(toolsDir).filter(f=>f.endsWith('.js'));
    res.json({ tools: files });
  });

  // Tool runner
  app.post('/tool/:name', async (req,res)=>{
    const name = req.params.name;
    const toolPath = path.join(__dirname,'tools', `${name}.js`);
    if(!fs.existsSync(toolPath)) return res.status(404).json({ error: 'Tool not found' });
    try {
      const tool = require(toolPath);
      const result = await tool.run(req.body.input || {});
      return res.json({ ok:true, tool:name, result });
    } catch (e) {
      pino.error({err:e, tool:name});
      return res.status(500).json({ ok:false, error: e.message || e.toString() });
    }
  });

  // session endpoints
  app.post('/session/create', async (req,res)=> {
    const payload = req.body || {};
    const session = await sessionManager.createSession(payload);
    res.json({ ok:true, session });
  });
  app.get('/session/status/:id', async (req,res)=> {
    const id = req.params.id;
    const s = await sessionManager.getSession(id);
    res.json({ ok:true, session: s });
  });
  app.post('/session/revoke/:id', async (req,res)=> {
    const id = req.params.id;
    await sessionManager.revokeSession(id);
    res.json({ ok:true });
  });

  // start scheduler
  scheduler.start();

  const PORT = process.env.PORT || 8080;
  app.listen(PORT, ()=> pino.info('MCP server listening on', PORT));
""")
(mcp / "server.js").write_text(server_js)

# sessionManager.js
session_js = textwrap.dedent("""\
  const fs = require('fs');
  const path = require('path');
  const crypto = require('crypto');
  const SESSIONS_FILE = path.join(__dirname, 'config', 'sessions.json');
  function load(){ try { return JSON.parse(fs.readFileSync(SESSIONS_FILE,'utf8')); } catch(e){ return {}; } }
  function save(s){ fs.writeFileSync(SESSIONS_FILE, JSON.stringify(s,null,2)); }
  async function createSession(payload){
    const id = crypto.randomBytes(12).toString('hex');
    const sessions = load();
    sessions[id] = { id, payload, createdAt: new Date().toISOString(), status: 'created' };
    save(sessions);
    return sessions[id];
  }
  async function getSession(id){ const sessions = load(); return sessions[id] || null; }
  async function revokeSession(id){ const sessions = load(); if(sessions[id]) sessions[id].status='revoked'; save(sessions); return true; }
  module.exports = { createSession, getSession, revokeSession };
""")
(mcp / "sessionManager.js").write_text(session_js)

# scheduler.js simple cron-like skeleton
scheduler_js = textwrap.dedent("""\
  const pino = require('pino')();
  let running = false;
  function start(){
    if(running) return;
    running = true;
    pino.info('Scheduler started');
    // Example: run every hour
    setInterval(()=> {
      pino.info('Scheduler tick - run auto-sync tasks (placeholder)');
      // call auto-sync tool via require('./tools/auto_sync').run(...)
    }, 1000 * 60 * 60);
  }
  module.exports = { start };
""")
(mcp / "scheduler.js").write_text(scheduler_js)

# scheduler config
(mcp / "config" / "scheduler.json").write_text(json.dumps({"interval_minutes":60}, indent=2))

# tools: youtube_saved.js
youtube_saved = textwrap.dedent("""\
  // youtube_saved.js
  // Moves liked videos to a user playlist (requires proper OAuth scopes).
  const axios = require('axios');
  async function listPlaylists(access_token){
    const url = `https://www.googleapis.com/youtube/v3/playlists?part=snippet&mine=true&maxResults=50`;
    const r = await axios.get(url, { headers: { Authorization: `Bearer ${access_token}` } });
    return r.data.items || [];
  }
  async function run(input){
    const { access_token } = input || {};
    if(!access_token) return { error: 'No access_token provided' };
    try {
      const playlists = await listPlaylists(access_token);
      return { success:true, playlists: playlists.map(p=>({ id:p.id, title:p.snippet.title })) };
    } catch(e){ return { success:false, error: e.message }; }
  }
  module.exports = { run };
""")
(tools / "youtube_saved.js").write_text(youtube_saved)

# tools: instagram_saved.js
instagram_saved = textwrap.dedent("""\
  // instagram_saved.js
  const axios = require('axios');
  async function run(input){
    const { access_token, filter } = input || {};
    if(!access_token) return { error: 'No access_token' };
    const url = `https://graph.instagram.com/me/media?fields=id,caption,media_type,media_url,permalink,thumbnail_url&access_token=${access_token}`;
    const r = await axios.get(url);
    const items = r.data.data || [];
    const filtered = (items||[]).filter(m => !filter || (m.caption && m.caption.toLowerCase().includes(filter.toLowerCase())));
    return { success:true, items: filtered.map(i=>({ id:i.id, caption:i.caption, url:i.media_url||i.thumbnail_url, permalink:i.permalink })) };
  }
  module.exports = { run };
""")
(tools / "instagram_saved.js").write_text(instagram_saved)

# tools: facebook_saved.js
facebook_saved = textwrap.dedent("""\
  // facebook_saved.js
  const axios = require('axios');
  async function run(input){
    const { access_token } = input || {};
    if(!access_token) return { error: 'No access_token' };
    // Placeholder: FB saved items API requires appropriate permissions & Graph API calls.
    return { success:true, items: [], note: 'Implement with Graph API and user permissions' };
  }
  module.exports = { run };
""")
(tools / "facebook_saved.js").write_text(facebook_saved)

# tools: google_places.js
google_places = textwrap.dedent("""\
  // google_places.js
  const axios = require('axios');
  async function run(input){
    const { query, location, apiKey } = input || {};
    const key = apiKey || process.env.GOOGLE_PLACES_KEY;
    if(!key) return { error: 'No API key provided' };
    const q = encodeURIComponent(query || '');
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${q}&key=${key}` + (location ? `&location=${location}` : '');
    const r = await axios.get(url);
    return { success:true, results: r.data.results || [] };
  }
  module.exports = { run };
""")
(tools / "google_places.js").write_text(google_places)

# tools: link_intel.js
link_intel = textwrap.dedent("""\
  // link_intel.js
  const axios = require('axios');
  async function fetchYouTube(url){
    // Basic metadata via oEmbed or API
    return { platform:'youtube', title: 'Sample', url };
  }
  async function run(input){
    const { url } = input || {};
    if(!url) return { error: 'No url' };
    if(url.includes('youtube.com') || url.includes('youtu.be')) return { success:true, meta: await fetchYouTube(url) };
    return { success:true, meta:{ platform:'unknown', url } };
  }
  module.exports = { run };
""")
(tools / "link_intel.js").write_text(link_intel)

# tools: content_intel.js
content_intel = textwrap.dedent("""\
  // content_intel.js - placeholder for LLM-based intelligence
  async function run(input){
    const texts = input.texts || [];
    if(!texts.length) return { success:false, error:'no texts' };
    // In prod call Gemini and parse structured output
    return { success:true, summary: texts.join(' ').slice(0,500) };
  }
  module.exports = { run };
""")
(tools / "content_intel.js").write_text(content_intel)

# tools: aggregator.js
aggregator = textwrap.dedent("""\
  // aggregator.js - marketplace search aggregator (placeholder)
  async function run(input){
    const tokens = input.tokens || [];
    return [{ platform:'mock', title: tokens.join(' '), price: 999, link: 'https://example.com' }];
  }
  module.exports = { run };
""")
(tools / "aggregator.js").write_text(aggregator)

# tools: verify.js
verify = textwrap.dedent("""\
  // verify.js - normalizes and scores listings
  async function run(input){
    const listings = input.listings || [];
    return listings.map(l => ({ ...l, availability_label: l.stock_status === 'in_stock' ? '✅ Available' : '❌ Out' }));
  }
  module.exports = { run };
""")
(tools / "verify.js").write_text(verify)

# tools: auto_sync.js (uses Playwright placeholder)
auto_sync = textwrap.dedent("""\
  // auto_sync.js - auto-save liked -> saved automation placeholder
  // WARNING: This is a template. In production implement secure session blobs or OAuth-based playlist moves.
  const { chromium } = require('playwright');
  async function run(input){
    // input: { platform, sessionBlob, userId }
    return { success:true, note: 'Auto-sync template. Implement Playwright automation with stored session.' };
  }
  module.exports = { run };
""")
(tools / "auto_sync.js").write_text(auto_sync)

# utils: logger and storage
utils_logger = textwrap.dedent("""\
  const pino = require('pino')();
  module.exports = pino;
""")
(utils / "logger.js").write_text(utils_logger)

utils_storage = textwrap.dedent("""\
  const fs = require('fs');
  module.exports = {
    saveJSON: (p,obj) => fs.writeFileSync(p, JSON.stringify(obj,null,2)),
    readJSON: (p) => { try { return JSON.parse(fs.readFileSync(p,'utf8')); } catch(e){ return null; } }
  };
""")
(utils / "storage.js").write_text(utils_storage)

# Dockerfile
dockerfile = textwrap.dedent("""\
  FROM node:18-bullseye
  WORKDIR /usr/src/app
  COPY package*.json ./
  RUN npm install --production
  COPY . .
  EXPOSE 8080
  CMD ["node","server.js"]
""")
(mcp / "Dockerfile").write_text(dockerfile)

# config files
(config / "sessions.json").write_text(json.dumps({}))
(config / "env.example.json").write_text(json.dumps({
  "MCP_PORT":8080,
  "YT_API_KEY":"your_yt_api_key",
  "GOOGLE_VISION_KEY":"your_google_vision_key",
  "GOOGLE_PLACES_KEY":"your_google_places_key"
}, indent=2))

# Firebase functions
firebase = base / "firebase_functions"
firebase.mkdir(parents=True, exist_ok=True)
(firebase / "package.json").write_text(json.dumps({
  "name":"autofinder-firebase",
  "version":"1.0.0",
  "main":"index.js",
  "dependencies":{"firebase-admin":"^11.10.0","firebase-functions":"^4.3.0","axios":"^1.4.0","@google/generative-ai":"^0.1.0"}
}, indent=2))

firebase_index = textwrap.dedent("""\
  const functions = require('firebase-functions');
  const admin = require('firebase-admin');
  const axios = require('axios');
  const { GoogleGenerativeAI } = require('@google/generative-ai');
  admin.initializeApp();
  const db = admin.firestore();
  const GEMINI_KEY = process.env.GEMINI_API_KEY || '';
  const MCP_URL = process.env.MCP_URL || 'http://localhost:8080';
  async function callTool(name,input){ const url = `${MCP_URL}/tool/${name}`; const r = await axios.post(url,{ input }, { timeout:30000 }); return r.data; }
  exports.storeTokens = functions.https.onRequest(async (req,res)=>{ const { userId, platform, tokens } = req.body; if(!userId||!platform||!tokens) return res.status(400).send('missing'); await db.collection('userTokens').doc(userId).set({ [platform]: tokens }, { merge:true }); res.json({ ok:true }); });
  exports.queryHandler = functions.https.onRequest(async (req,res)=>{ try { const { text, userId } = req.body || {}; const gm = new GoogleGenerativeAI(GEMINI_KEY); const model = gm.getGenerativeModel({ model: process.env.MODEL_TYPE || 'gemini-1.5-flash' }); const prompt = `Parse the user text into JSON with keys: intent (reel_search|video_search|product_search|nearby), platform, query. User text: ${text}`; const reply = await model.generateContent(prompt); const parsed = JSON.parse(reply.response.text().match(/\\{[\\s\\S]*\\}/)[0]); let aggregated = {}; if(parsed.intent === 'product_search'){ const tokens = parsed.query ? parsed.query.split(' ') : [parsed.query]; const agg = await callTool('aggregator', { tokens }); aggregated = agg.result || agg; } else if(parsed.intent === 'reel_search'){ const userDoc = await admin.firestore().collection('users').doc(userId).get(); const data = userDoc.exists ? userDoc.data() : {}; const ig_tokens = data && data.ig_tokens; const inst = await callTool('instagram_saved', { access_token: ig_tokens ? ig_tokens.access_token : null, filter: parsed.query }); aggregated = inst.result || inst; } else { const yt = await callTool('youtube_saved', { query: parsed.query || 'trending' }); aggregated = yt.result || yt; } res.json({ ok:true, parsed, aggregated }); } catch(e){ console.error(e); res.status(500).json({ ok:false, error: e.message }); } });
""")
(firebase / "index.js").write_text(firebase_index)

# Firestore models & schema examples
models_dir = firebase / "models"
models_dir.mkdir(parents=True, exist_ok=True)
models_dir.joinpath("firestore_schema.md").write_text(textwrap.dedent("""\
  Firestore schema (recommended):
  - users/{userId}
    - platforms: { instagram: { access_token, refresh_token, expires_at }, youtube: {...} }
    - savedIndex/{platform}/{docId} -> { url, title, platform, tags, savedAt }
  - jobs/{jobId} -> auto-sync job metadata
"""))

# Chrome extension (manifest v3 + background + content + popup)
chrome = base / "chrome_extension"
chrome.mkdir(parents=True, exist_ok=True)
(chrome / "manifest.json").write_text(json.dumps({
  "manifest_version":3,
  "name":"AutoFinder AutoSave",
  "version":"1.0",
  "permissions":["tabs","storage","alarms","activeTab","scripting"],
  "background":{"service_worker":"background.js"},
  "host_permissions":["*://*.youtube.com/*","*://*.instagram.com/*"],
  "action":{"default_popup":"popup.html"}
}, indent=2))
(chrome / "background.js").write_text(textwrap.dedent("""\
// background.js - listens for user opt-in and schedules periodic scans
chrome.runtime.onInstalled.addListener(()=> {
  chrome.alarms.create('autoscan', { periodInMinutes: 60 });
});
chrome.alarms.onAlarm.addListener((alarm) => {
  if(alarm.name==='autoscan'){
    // trigger content script on active tabs or use background fetch
    chrome.tabs.query({}, (tabs)=> {
      tabs.forEach(t => {
        if(t.url && (t.url.includes('youtube.com')||t.url.includes('instagram.com'))){
          chrome.scripting.executeScript({ target:{tabId:t.id}, files:['content.js'] });
        }
      });
    });
  }
});
chrome.runtime.onMessage.addListener((msg, sender, sendResp)=> {
  if(msg.type==='saveLink') {
    // store in chrome storage and send to backend later
    chrome.storage.local.get(['savedLinks'], (res)=> {
      const arr = res.savedLinks || [];
      arr.push(msg.link);
      chrome.storage.local.set({ savedLinks: arr }, ()=> sendResp({ ok:true }));
    });
    return true;
  }
});
"""))
(chrome / "content.js").write_text(textwrap.dedent("""\
// content.js - extracts current video link and sends to background
(function(){
  const url = location.href;
  chrome.runtime.sendMessage({ type:'saveLink', link: url }, (resp)=>{ /* ack */ });
})();
"""))
(chrome / "popup.html").write_text(textwrap.dedent("""\
<!doctype html><html><body>
<h3>AutoFinder AutoSave</h3>
<button id="sync">Sync Now</button>
<script>
document.getElementById('sync').onclick = async () => {
  chrome.storage.local.get(['savedLinks'], (res) => {
    const links = res.savedLinks || [];
    // POST to backend endpoint /api/syncLinks (implement auth)
    fetch('https://your-backend.example.com/api/syncLinks', { method:'POST', headers:{'Content-Type':'application/json'}, body: JSON.stringify({ links }) }).then(r=>r.json()).then(console.log);
  });
};
</script>
</body></html>
"""))

# android helper doc
(android := base / "android_helper").mkdir(parents=True, exist_ok=True)
(android / "android_bridge.md").write_text(textwrap.dedent("""\
Android Helper (Accessibility) - Instructions
- This helper app uses AccessibilityService to detect when user likes a video and can auto-save link to your backend.
- Flow:
  1) User installs helper and grants Accessibility permission.
  2) When user taps 'like' on supported apps, helper captures current URL (or share intent) and POSTs to backend /api/saveLink.
  3) Backend triggers MCP auto-sync or indexing.
- Important: respect user privacy and make opt-in explicit.
"""))

# API endpoint examples in mcp-server: create syncLinks endpoint
sync_api = textwrap.dedent("""\
  // append to server.js or use as separate route file - example POST /api/syncLinks
  /*
  app.post('/api/syncLinks', async (req,res)=>{
    const { links, userId } = req.body;
    // validate, authenticate, store in DB, and trigger indexing
    res.json({ ok:true, count: links.length });
  });
  */
""")
(mcp / "API_NOTES.txt").write_text(sync_api)

# README top-level
(base / "README.md").write_text(textwrap.dedent("""\
AutoFinder MCP Updated - unified package with additions
Includes:
- MCP server with API layer and scheduler
- Tool pack: youtube_saved, instagram_saved, facebook_saved, google_places, link_intel, content_intel, aggregator, verify, auto_sync
- Chrome extension for auto-saving links (manifest v3)
- Android helper design doc for Accessibility-based capture
- Firebase functions skeleton + Firestore schema sample
- Dockerfile for MCP server
Notes:
- Playwright/automation is provided as a template. Use OAuth/session blob strategy in prod.
- Replace placeholders and secure tokens before deployment.
"""))

# Zip everything
zip_path = Path("/mnt/data/autofinder_mcp_updated.zip")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for fp in base.rglob("*"):
        z.write(fp, fp.relative_to(base))

zip_path
