// sample_backend.js - minimal Express server (example)
const express = require('express');
const bodyParser = require('body-parser');
const fetch = require('node-fetch'); // or native fetch in newer Node
const app = express();
app.use(bodyParser.json());

app.post('/api/query', async (req, res) => {
  const { query, location, token } = req.body;
  // 1) Call LLM to parse intent (pseudo)
  // 2) If intent = nearby -> call Google Places API
  // 3) If intent = recall -> call Google Timeline with token's linked account
  // 4) Return aggregated results
  res.json({ session_id: 'sess-123', results: [] });
});

app.post('/api/nearby', async (req, res) => {
  const { lat, lng, type } = req.body;
  // call Google Places API (replace API_KEY)
  // Example: https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=lat,lng&radius=1000&type=restaurant&key=API_KEY
  res.json({ results: [] });
});

app.listen(3000, () => console.log('Server running on port 3000'));