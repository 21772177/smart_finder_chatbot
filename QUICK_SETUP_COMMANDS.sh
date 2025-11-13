#!/bin/bash

# Quick Setup Commands - Copy and paste these after getting your credentials
# Replace YOUR_*_HERE with actual values from the setup process

echo "🚀 Smart Finder Chatbot - Quick Setup Commands"
echo "=============================================="
echo ""
echo "📋 Follow these steps:"
echo ""
echo "1. Get your credentials from:"
echo "   - Google Cloud Console (YouTube, Google Maps, Google OAuth)"
echo "   - Facebook Developers (Instagram, Facebook)"
echo ""
echo "2. Copy and paste the commands below, replacing YOUR_*_HERE with actual values"
echo ""
echo "3. Run: firebase deploy --only functions"
echo ""
echo "=============================================="
echo ""

cat << 'EOF'
# YouTube OAuth
firebase functions:config:set youtube.client_id="YOUR_YOUTUBE_CLIENT_ID_HERE"
firebase functions:config:set youtube.client_secret="YOUR_YOUTUBE_CLIENT_SECRET_HERE"

# YouTube Data API
firebase functions:config:set youtube.key="YOUR_YOUTUBE_API_KEY_HERE"

# Instagram OAuth
firebase functions:config:set instagram.client_id="YOUR_INSTAGRAM_CLIENT_ID_HERE"
firebase functions:config:set instagram.client_secret="YOUR_INSTAGRAM_CLIENT_SECRET_HERE"

# Facebook OAuth
firebase functions:config:set facebook.app_id="YOUR_FACEBOOK_APP_ID_HERE"
firebase functions:config:set facebook.app_secret="YOUR_FACEBOOK_APP_SECRET_HERE"

# Google Maps API
firebase functions:config:set google.maps_key="YOUR_GOOGLE_MAPS_API_KEY_HERE"

# Google OAuth (Optional - for Timeline)
firebase functions:config:set google.client_id="YOUR_GOOGLE_CLIENT_ID_HERE"
firebase functions:config:set google.client_secret="YOUR_GOOGLE_CLIENT_SECRET_HERE"

# Deploy
firebase deploy --only functions
EOF

echo ""
echo "=============================================="
echo "📚 For detailed step-by-step instructions, see:"
echo "   COMPLETE_SETUP_GUIDE.md"
echo ""

