Sample Requests & Responses

1) Query - Nearby food
Request:
POST /api/query
{
  "query": "Where can we eat here North Indian?",
  "location": {"lat": 12.9716, "lng": 77.5946},
  "token": "device-uuid-123"
}

Response:
{
  "session_id": "sess-abc-123",
  "results": [
    {"platform":"maps", "title":"Empire Restaurant", "distance_m":400, "rating":4.3, "open_now":true, "url":"https://maps.google.com/?q=..."},
    {"platform":"zomato", "title":"Tandoori Treats", "distance_m":650, "rating":4.1, "open_now":true, "url":"..."}
  ]
}

2) Query - Recall last visit
Request:
POST /api/recall
{
  "token": "device-uuid-123",
  "location": {"lat": 12.9716, "lng": 77.5946}
}

Response:
{
  "last_visit": {"place":"Empire Restaurant", "date":"2025-08-20T20:12:00Z", "source":"google_timeline"}
}
