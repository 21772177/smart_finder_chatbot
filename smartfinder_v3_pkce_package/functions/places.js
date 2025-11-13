
const axios = require("axios");

exports.fetchPlaces = async (req, res, data) => {
  try {
    const location = encodeURIComponent(data.location || (req.body.location && (req.body.location.lat + ',' + req.body.location.lng)) || "nearby");
    const type = data.type || "restaurant";
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${type}+in+${location}&key=${process.env.GOOGLE_MAPS_KEY}`;
    const response = await axios.get(url);
    const results = response.data.results.slice(0, 6).map(p => ({
      name: p.name,
      address: p.formatted_address,
      rating: p.rating,
      place_id: p.place_id,
      maps_url: `https://www.google.com/maps/place/?q=place_id:${p.place_id}`,
      photo_reference: p.photos && p.photos.length ? p.photos[0].photo_reference : null
    }));
    const withPhotos = results.map(r => {
      if(r.photo_reference) {
        r.photo_url = `https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${r.photo_reference}&key=${process.env.GOOGLE_MAPS_KEY}`;
      }
      return r;
    });
    res.json({ reply: data.reply, results: withPhotos });
  } catch (e) {
    console.error(e.response && e.response.data ? e.response.data : e.message);
    res.status(500).json({ error: e.message });
  }
};
