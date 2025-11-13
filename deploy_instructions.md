Deploy Instructions (MVP)

1) Frontend
 - Deploy React app to Vercel or Netlify
 - Ensure CORS allows your backend origin

2) Backend
 - Host Node.js server on Render / Heroku / AWS Elastic Beanstalk
 - Use HTTPS and set environment variables for API keys

3) Secrets Management
 - Keep API keys in environment variables
 - Do not commit keys to git

4) OAuth
 - Configure redirect URIs to your deployed domain
 - Use secure cookie or PKCE for client-side auth

5) Scaling
 - Use Redis for session caching if concurrent users grow
 - Monitor API quota for Google and YouTube; implement rate-limiters
