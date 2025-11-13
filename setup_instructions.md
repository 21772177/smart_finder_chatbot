Setup & Deployment Instructions (quick)

1) Install Firebase CLI:
   npm install -g firebase-tools

2) Login and init:
   firebase login
   firebase init functions hosting

3) Copy this project into your working folder.

4) Set environment variables:
   firebase functions:config:set openai.key="YOUR_KEY" google.maps="YOUR_KEY" whatsapp.token="YOUR_TOKEN"

5) Install functions dependencies:
   cd functions
   npm install

6) Deploy:
   firebase deploy --only functions,hosting

7) After deploy:
   - Visit your site (Firebase hosting URL)
   - Test POST /api/query via fetch or Postman

Notes:
 - Replace mock implementations in functions/index.js with real API calls before production.
 - Set up OAuth for Google Timeline and implement user consent flows for recall.
