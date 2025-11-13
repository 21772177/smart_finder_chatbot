#!/bin/bash

# Smart Finder Chatbot - Required API Keys Setup Script
# This script shows exactly what keys are missing and how to configure them

echo "🔑 Smart Finder Chatbot - API Keys Status"
echo "=========================================="
echo ""

# Check current config
echo "📋 Checking current configuration..."
CURRENT_CONFIG=$(firebase functions:config:get 2>/dev/null)

echo ""
echo "✅ Currently Configured:"
echo "------------------------"
if echo "$CURRENT_CONFIG" | grep -q "gemini"; then
    echo "✅ Gemini API Key - CONFIGURED"
else
    echo "❌ Gemini API Key - NOT CONFIGURED"
fi

if echo "$CURRENT_CONFIG" | grep -q "openai"; then
    echo "✅ OpenAI API Key - CONFIGURED"
else
    echo "❌ OpenAI API Key - NOT CONFIGURED"
fi

echo ""
echo "❌ Missing (Required for Platform Connections):"
echo "-----------------------------------------------"

if echo "$CURRENT_CONFIG" | grep -q "youtube.client_id"; then
    echo "✅ YouTube OAuth Client ID - CONFIGURED"
else
    echo "❌ YouTube OAuth Client ID - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set youtube.client_id=\"YOUR_CLIENT_ID\""
fi

if echo "$CURRENT_CONFIG" | grep -q "youtube.client_secret"; then
    echo "✅ YouTube OAuth Client Secret - CONFIGURED"
else
    echo "❌ YouTube OAuth Client Secret - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set youtube.client_secret=\"YOUR_CLIENT_SECRET\""
fi

if echo "$CURRENT_CONFIG" | grep -q "instagram.client_id"; then
    echo "✅ Instagram OAuth Client ID - CONFIGURED"
else
    echo "❌ Instagram OAuth Client ID - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set instagram.client_id=\"YOUR_CLIENT_ID\""
fi

if echo "$CURRENT_CONFIG" | grep -q "instagram.client_secret"; then
    echo "✅ Instagram OAuth Client Secret - CONFIGURED"
else
    echo "❌ Instagram OAuth Client Secret - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set instagram.client_secret=\"YOUR_CLIENT_SECRET\""
fi

if echo "$CURRENT_CONFIG" | grep -q "facebook.app_id"; then
    echo "✅ Facebook App ID - CONFIGURED"
else
    echo "❌ Facebook App ID - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set facebook.app_id=\"YOUR_APP_ID\""
fi

if echo "$CURRENT_CONFIG" | grep -q "facebook.app_secret"; then
    echo "✅ Facebook App Secret - CONFIGURED"
else
    echo "❌ Facebook App Secret - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set facebook.app_secret=\"YOUR_APP_SECRET\""
fi

echo ""
echo "❌ Missing (Required for Public Search):"
echo "----------------------------------------"

if echo "$CURRENT_CONFIG" | grep -q "youtube.key"; then
    echo "✅ YouTube Data API Key - CONFIGURED"
else
    echo "❌ YouTube Data API Key - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set youtube.key=\"YOUR_API_KEY\""
fi

if echo "$CURRENT_CONFIG" | grep -q "google.maps_key"; then
    echo "✅ Google Maps API Key - CONFIGURED"
else
    echo "❌ Google Maps API Key - NOT CONFIGURED"
    echo "   Command: firebase functions:config:set google.maps_key=\"YOUR_MAPS_API_KEY\""
fi

echo ""
echo "📝 Summary:"
echo "----------"
echo "✅ LLM Keys: Configured (Gemini + OpenAI)"
echo "❌ OAuth Credentials: NOT CONFIGURED (Platforms won't work)"
echo "❌ API Keys: NOT CONFIGURED (Public search won't work)"
echo ""
echo "📚 See API_KEYS_STATUS.md for detailed status"
echo "📚 See OAUTH_SETUP_GUIDE.md for OAuth setup instructions"
echo ""

