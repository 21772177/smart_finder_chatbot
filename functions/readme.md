# Firebase Functions - Notes

- index.js contains sample endpoints for /api/query, /api/nearby, /api/recall.
- You must replace mock functions (searchPlaces, recallLastVisit) with real API calls:
  - Google Places API: https://developers.google.com/maps/documentation/places/web-service/overview
  - Google Timeline API (Location History): Requires user OAuth and access via Google APIs.
- Set environment variables in Firebase with `firebase functions:config:set` or use Secret Manager.
