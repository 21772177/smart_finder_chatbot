Sprint Plan - 12 Weeks (MVP)

Week 1-2: Research & Planning
 - Finalize APIs and permissions
 - Create intent taxonomy
 - Prepare developer access for Google & YouTube APIs

Week 3-4: Core AI & Backend
 - Implement /api/query parser
 - Integrate OpenAI (or chosen LLM) for intent extraction
 - Start basic response formatting

Week 5-6: Live Data Integration
 - Add Google Maps Places API
 - Add Zomato/place listing connector
 - Implement nearby search logic

Week 7: Token Memory Logic
 - Implement device token generation (client-side)
 - Implement /api/recall endpoint with Google Timeline support

Week 8: Frontend Chat UI
 - Build web chatbot UI (React)
 - Connect to /api/query

Week 9: Privacy & Cache
 - Implement ephemeral cache with Redis (optional)
 - Implement auto-clear behaviour and privacy notice

Week 10: QA & Testing
 - Unit and integration tests
 - Test across multiple locations & saved content scenarios

Week 11-12: Beta Launch & Feedback
 - Deploy to staging and collect 100 beta users
 - Iterate on UX and fix issues
