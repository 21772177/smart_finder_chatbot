WhatsApp Integration Options

Option A: Meta WhatsApp Cloud API (recommended for small teams)
 - Create Facebook Developer App
 - Add WhatsApp Product and configure phone number
 - Use Cloud API to receive and send messages (webhooks)
 - Costs: Meta may charge per-message rates in some regions; check latest pricing.

Option B: Twilio WhatsApp API
 - Twilio provides WhatsApp Business API access
 - Pricing: Twilio charges per-message; affordable for small volumes
 - Easy webhook integration with Firebase Functions.

Webhook flow:
 - WhatsApp -> Meta/Twilio -> your Firebase Function webhook -> process message -> respond via API.

Security:
 - Validate webhook signature
 - Throttle responses to avoid spam
