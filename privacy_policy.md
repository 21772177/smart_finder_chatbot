Privacy & Data Handling - Smart Finder AI Chatbot (MVP)

Principles:
 - No permanent storage on chatbot servers of user personal data
 - Device-based anonymous token for recall stored client-side
 - All external API calls are on-demand and results are discarded after session
 - Users may optionally grant Google Timeline read-only access for long-term recall
 - OAuth tokens should be stored only in browser session storage and not persisted on server
 - Users can clear their local token and history anytime (button available in UI)

Data Retention:
 - Server-side transient cache: max 30 minutes
 - Client-side token: until user clears it (user-controlled)
 - No analytics or PII collected unless user opts in (explicit consent required)
