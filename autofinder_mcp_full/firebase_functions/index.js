const functions = require('firebase-functions');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const GEMINI_KEY = process.env.GEMINI_API_KEY || '';
const MCP_URL = process.env.MCP_URL || 'http://localhost:8080';
async function callTool(name, input) { const url = `${MCP_URL}/tool/${name}`; const r = await axios.post(url, { input }, { timeout: 30000 }); return r.data; }
exports.queryHandler = functions.https.onRequest(async (req, res) => {
  try {
    const { text, ig_access, yt_access } = req.body || {};
    const gen = new GoogleGenerativeAI(GEMINI_KEY);
    const model = gen.getGenerativeModel({ model: process.env.MODEL_TYPE || 'gemini-1.5-flash' });
    const prompt = `You are SmartFinder. Parse the user text into JSON with keys: intent (reel_search|video_search|product_search|nearby), platform (instagram|youtube|any), query.` + "\nUser: " + (text || '');
    const reply = await model.generateContent(prompt);
    const parsed = JSON.parse(reply.response.text().match(/\{[\s\S]*\}/)[0]);
    let aggregated = {};
    if(parsed.intent === 'reel_search' && parsed.platform !== 'youtube') {
      const toolRes = await callTool('instagram', { access_token: ig_access, filter: parsed.query });
      aggregated = toolRes.result || toolRes;
    } else if(parsed.intent === 'video_search') {
      const toolRes = await callTool('youtube', { query: parsed.query, access_token: yt_access, user_mode: parsed.platform === 'youtube' ? 'likes' : undefined });
      aggregated = toolRes.result || toolRes;
    } else if(parsed.intent === 'product_search') {
      const tokens = parsed.query ? parsed.query.split(' ') : [parsed.query];
      const agg = await callTool('aggregator', { tokens });
      aggregated = agg.result || agg;
    } else {
      const toolRes = await callTool('youtube', { query: parsed.query || 'trending' });
      aggregated = toolRes.result || toolRes;
    }
    res.json({ ok:true, parsed, aggregated });
  } catch (e) {
    console.error(e);
    res.status(500).json({ ok:false, error: e.message });
  }
});
