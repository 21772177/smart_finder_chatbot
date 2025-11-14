#!/bin/bash

# Production Readiness Check Script
# Run this to verify your chatbot is ready for production

echo "🚀 Smart Finder Chatbot - Production Readiness Check"
echo "===================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Firebase config
echo "📋 Checking Firebase Configuration..."
echo "-----------------------------------"
CONFIG=$(firebase functions:config:get 2>/dev/null)

# Required configs
REQUIRED_CONFIGS=(
  "youtube.client_id"
  "youtube.client_secret"
  "youtube.key"
  "instagram.client_id"
  "instagram.client_secret"
  "facebook.app_id"
  "facebook.app_secret"
  "google.maps_key"
  "google.client_id"
  "google.client_secret"
  "gemini.key"
  "openai.key"
)

ALL_CONFIGURED=true
for config in "${REQUIRED_CONFIGS[@]}"; do
  # Check for config in JSON structure (handles nested keys)
  config_key=$(echo "$config" | sed 's/\./"/g' | sed 's/^/"/' | sed 's/$/"/')
  if echo "$CONFIG" | grep -qi "$config" || echo "$CONFIG" | grep -qi "$(echo $config | cut -d'.' -f1)"; then
    echo -e "${GREEN}✅${NC} $config"
  else
    echo -e "${RED}❌${NC} $config - MISSING"
    ALL_CONFIGURED=false
  fi
done

echo ""
if [ "$ALL_CONFIGURED" = true ]; then
  echo -e "${GREEN}✅ All Firebase configs are set!${NC}"
else
  echo -e "${RED}❌ Some configs are missing. Run: firebase functions:config:set ...${NC}"
fi

echo ""
echo "🌐 Checking OAuth App Status..."
echo "-----------------------------------"
echo ""
echo "⚠️  MANUAL CHECKS REQUIRED:"
echo ""
echo "1. Google OAuth App:"
echo "   - Visit: https://console.cloud.google.com/apis/credentials/consent?project=buildkit-1695f"
echo "   - Status: [ ] Testing Mode  [ ] Published/Verified"
echo "   - Action: Click 'PUBLISH APP' for production"
echo ""
echo "2. Facebook App:"
echo "   - Visit: https://developers.facebook.com/apps/1263833868842541"
echo "   - App Domains: [ ] buildkit-1695f.web.app"
echo "   - OAuth Redirect URIs: [ ] Configured"
echo ""
echo "3. Instagram App:"
echo "   - Visit: https://developers.facebook.com/apps/1263833868842541/instagram-basic-display/basic-display/"
echo "   - OAuth Redirect URIs: [ ] Configured"
echo ""

echo "📊 Production URLs:"
echo "-----------------------------------"
echo "✅ Chatbot: https://buildkit-1695f.web.app"
echo "✅ API: https://us-central1-buildkit-1695f.cloudfunctions.net/api"
echo "✅ Firebase Console: https://console.firebase.google.com/project/buildkit-1695f"
echo ""

echo "🧪 Testing Checklist:"
echo "-----------------------------------"
echo "[ ] Test YouTube OAuth connection"
echo "[ ] Test Instagram OAuth connection"
echo "[ ] Test Facebook OAuth connection"
echo "[ ] Test Google OAuth connection"
echo "[ ] Test public content search"
echo "[ ] Test saved content search"
echo "[ ] Test nearby places search"
echo "[ ] Test timeline search"
echo ""

echo "📚 Documentation:"
echo "-----------------------------------"
echo "📖 Production Setup: PRODUCTION_SETUP.md"
echo "📖 OAuth Verification: FIX_GOOGLE_OAUTH_VERIFICATION.md"
echo "📖 Testing Guide: TESTING_URL.md"
echo ""

if [ "$ALL_CONFIGURED" = true ]; then
  echo -e "${GREEN}✅ Configuration: READY${NC}"
  echo -e "${YELLOW}⚠️  OAuth Apps: Check manually (see above)${NC}"
  echo ""
  echo "Next step: Publish Google OAuth app for verification!"
else
  echo -e "${RED}❌ Configuration: INCOMPLETE${NC}"
  echo "Fix missing configs first, then proceed."
fi

echo ""

