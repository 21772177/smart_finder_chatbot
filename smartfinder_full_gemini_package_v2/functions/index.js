
const functions = require("firebase-functions");
const express = require("express");
const bodyParser = require("body-parser");
const { queryHandler } = require("./query");
const { fetchPlaces } = require("./places");
const { recallVisit } = require("./timeline");
const { fetchReels } = require("./instagram");
const { fetchVideos } = require("./youtube");
const { oauthRoutes } = require("./auth");

const app = express();
app.use(bodyParser.json());
app.use("/auth", oauthRoutes); // OAuth endpoints for Google, Instagram, YouTube

app.post("/api/query", async (req, res) => {
  try {
    const data = await queryHandler(req.body);
    if (data.intent === "nearby_search") return fetchPlaces(req, res, data);
    if (data.intent === "recall_visit") return recallVisit(req, res, data);
    if (data.intent === "reel_search") return fetchReels(req, res, data);
    if (data.intent === "video_search") return fetchVideos(req, res, data);
    return res.json({ reply: data.reply });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: e.message });
  }
});

exports.api = functions.https.onRequest(app);
