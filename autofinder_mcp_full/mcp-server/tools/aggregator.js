const axios = require('axios');
const APIFY_TOKEN = process.env.APIFY_TOKEN || '';
const TEMU_API = process.env.TEMU_API || '';
const FLIPKART_API = process.env.FLIPKART_API || '';
async function callApifyAli(tokens) { if(!APIFY_TOKEN) return []; return []; }
async function callTemu(tokens) { if(!TEMU_API) return []; try { const q = encodeURIComponent(tokens.join(' ')); const url = `${TEMU_API}/search?q=${q}`; const r = await axios.get(url); return r.data.items || []; } catch(e) { return []; } }
async function callFlipkart(tokens) { if(!FLIPKART_API) return []; try { const q = encodeURIComponent(tokens.join(' ')); const url = `${FLIPKART_API}/search?q=${q}`; const r = await axios.get(url); return r.data.items || []; } catch(e) { return []; } }
async function callAmazon(tokens) { return []; }
async function run(input) {
  const tokens = input.tokens || [];
  let results = [];
  results = results.concat(await callApifyAli(tokens));
  results = results.concat(await callTemu(tokens));
  results = results.concat(await callFlipkart(tokens));
  results = results.concat(await callAmazon(tokens));
  const seen = new Set(); const merged = [];
  for(const r of results) { const key = (r.link||r.title||'').toString().slice(0,200); if(seen.has(key)) continue; seen.add(key); merged.push(r); if(merged.length>=40) break; }
  return merged;
}
module.exports = { run };
