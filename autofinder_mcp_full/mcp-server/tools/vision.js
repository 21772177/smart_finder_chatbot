const axios = require('axios');
const API_KEY = process.env.GOOGLE_VISION_KEY || '';
async function annotate(image_base64) {
  const url = `https://vision.googleapis.com/v1/images:annotate?key=${API_KEY}`;
  const body = { requests: [ { image: { content: image_base64.split(',').pop() }, features: [{ type: 'LABEL_DETECTION', maxResults: 10 }, { type: 'TEXT_DETECTION', maxResults: 5 }] } ] };
  const r = await axios.post(url, body);
  return r.data;
}
async function run(input) {
  const { image_base64 } = input || {};
  if(!image_base64) return { error: 'No image provided' };
  if(!API_KEY) return { mock: true, msg: 'No GOOGLE_VISION_KEY set' };
  const resp = await annotate(image_base64);
  const labels = resp.responses[0].labelAnnotations || [];
  const texts = resp.responses[0].textAnnotations || [];
  return { labels: labels.map(l=>l.description), ocr: texts.length ? texts[0].description : '' };
}
module.exports = { run };
