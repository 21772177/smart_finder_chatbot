#!/bin/bash

# Smart Finder Chatbot - Pre-Testing Verification Script
# This script verifies everything is ready for testing

echo "🔍 Smart Finder Chatbot - Pre-Testing Verification"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Firebase project
echo "📋 Checking Firebase project..."
PROJECT=$(firebase use 2>/dev/null | grep "Active Project" | awk '{print $NF}')
if [ -n "$PROJECT" ]; then
    echo -e "${GREEN}✅ Firebase project: $PROJECT${NC}"
else
    echo -e "${YELLOW}⚠️  Firebase project not set. Run: firebase use buildkit-1695f${NC}"
fi

# Check Firebase Functions config
echo ""
echo "🔑 Checking API Keys Configuration..."
echo ""

# Check OpenAI
OPENAI_KEY=$(firebase functions:config:get openai.key 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$OPENAI_KEY" ] && [ "$OPENAI_KEY" != "null" ]; then
    echo -e "${GREEN}✅ OpenAI API Key: Configured${NC}"
else
    echo -e "${RED}❌ OpenAI API Key: NOT CONFIGURED${NC}"
fi

# Check Gemini
GEMINI_KEY=$(firebase functions:config:get gemini.key 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$GEMINI_KEY" ] && [ "$GEMINI_KEY" != "null" ]; then
    echo -e "${GREEN}✅ Gemini API Key: Configured${NC}"
else
    echo -e "${RED}❌ Gemini API Key: NOT CONFIGURED${NC}"
fi

# Check YouTube OAuth
YT_CLIENT_ID=$(firebase functions:config:get youtube.client_id 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
YT_CLIENT_SECRET=$(firebase functions:config:get youtube.client_secret 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$YT_CLIENT_ID" ] && [ "$YT_CLIENT_ID" != "null" ] && [ -n "$YT_CLIENT_SECRET" ] && [ "$YT_CLIENT_SECRET" != "null" ]; then
    echo -e "${GREEN}✅ YouTube OAuth: Configured${NC}"
else
    echo -e "${RED}❌ YouTube OAuth: NOT CONFIGURED${NC}"
fi

# Check YouTube API Key
YT_KEY=$(firebase functions:config:get youtube.key 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$YT_KEY" ] && [ "$YT_KEY" != "null" ]; then
    echo -e "${GREEN}✅ YouTube API Key: Configured${NC}"
else
    echo -e "${RED}❌ YouTube API Key: NOT CONFIGURED${NC}"
fi

# Check Instagram OAuth
IG_CLIENT_ID=$(firebase functions:config:get instagram.client_id 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
IG_CLIENT_SECRET=$(firebase functions:config:get instagram.client_secret 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$IG_CLIENT_ID" ] && [ "$IG_CLIENT_ID" != "null" ] && [ -n "$IG_CLIENT_SECRET" ] && [ "$IG_CLIENT_SECRET" != "null" ]; then
    echo -e "${GREEN}✅ Instagram OAuth: Configured${NC}"
else
    echo -e "${RED}❌ Instagram OAuth: NOT CONFIGURED${NC}"
fi

# Check Facebook OAuth
FB_APP_ID=$(firebase functions:config:get facebook.app_id 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
FB_APP_SECRET=$(firebase functions:config:get facebook.app_secret 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$FB_APP_ID" ] && [ "$FB_APP_ID" != "null" ] && [ -n "$FB_APP_SECRET" ] && [ "$FB_APP_SECRET" != "null" ]; then
    echo -e "${GREEN}✅ Facebook OAuth: Configured${NC}"
else
    echo -e "${RED}❌ Facebook OAuth: NOT CONFIGURED${NC}"
fi

# Check Google Maps
GMAPS_KEY=$(firebase functions:config:get google.maps_key 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$GMAPS_KEY" ] && [ "$GMAPS_KEY" != "null" ]; then
    echo -e "${GREEN}✅ Google Maps API Key: Configured${NC}"
else
    echo -e "${YELLOW}⚠️  Google Maps API Key: NOT CONFIGURED (Optional)${NC}"
fi

# Check Google OAuth
GOOGLE_CLIENT_ID=$(firebase functions:config:get google.client_id 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
GOOGLE_CLIENT_SECRET=$(firebase functions:config:get google.client_secret 2>/dev/null | grep -o '"[^"]*"' | tr -d '"')
if [ -n "$GOOGLE_CLIENT_ID" ] && [ "$GOOGLE_CLIENT_ID" != "null" ] && [ -n "$GOOGLE_CLIENT_SECRET" ] && [ "$GOOGLE_CLIENT_SECRET" != "null" ]; then
    echo -e "${GREEN}✅ Google OAuth: Configured${NC}"
else
    echo -e "${YELLOW}⚠️  Google OAuth: NOT CONFIGURED (Optional)${NC}"
fi

echo ""
echo "📦 Checking Code Files..."
echo ""

# Check if main files exist
if [ -f "functions/index.js" ]; then
    echo -e "${GREEN}✅ functions/index.js: Exists${NC}"
else
    echo -e "${RED}❌ functions/index.js: MISSING${NC}"
fi

if [ -f "public/index.html" ]; then
    echo -e "${GREEN}✅ public/index.html: Exists${NC}"
else
    echo -e "${RED}❌ public/index.html: MISSING${NC}"
fi

if [ -f "functions/services/directOAuth.js" ]; then
    echo -e "${GREEN}✅ functions/services/directOAuth.js: Exists${NC}"
else
    echo -e "${RED}❌ functions/services/directOAuth.js: MISSING${NC}"
fi

echo ""
echo "🌐 Checking Deployment Status..."
echo ""

# Check if functions are deployed
echo -e "${YELLOW}ℹ️  To check if functions are deployed, run:${NC}"
echo "   firebase functions:list"
echo ""

# Check hosting URL
echo -e "${YELLOW}ℹ️  Chatbot URL should be:${NC}"
echo "   https://buildkit-1695f.web.app"
echo ""

echo "=================================================="
echo "📋 Next Steps:"
echo ""
echo "1. ✅ Add test users to Google OAuth:"
echo "   https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f"
echo ""
echo "2. ✅ Test chatbot at:"
echo "   https://buildkit-1695f.web.app"
echo ""
echo "3. ✅ Test OAuth connections:"
echo "   - YouTube"
echo "   - Instagram"
echo "   - Facebook"
echo "   - Google"
echo ""
echo "=================================================="

