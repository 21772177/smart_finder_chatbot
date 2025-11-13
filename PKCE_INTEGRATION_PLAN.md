# PKCE Integration Plan

## Overview
Integrating smartfinder_v3_pkce_package with existing system to add:
- PKCE OAuth (more secure)
- Popup-based OAuth flows
- Client-side token storage
- Enhanced query handlers

## Integration Steps

### 1. OAuth System
- Merge PKCE OAuth handlers with existing oauthHandlers.js
- Keep existing device token system
- Add PKCE support for Google/YouTube
- Maintain Instagram OAuth

### 2. Query System
- Merge query.js with existing LLM service
- Keep RAG and Agentic Router
- Enhance intent parsing with PKCE package logic

### 3. Frontend
- Update to use PKCE OAuth flows
- Keep existing UI
- Add popup-based OAuth
- Maintain device token system

### 4. Environment Variables
- Add PKCE OAuth credentials
- Keep existing configs
- Update Firebase config

## Files to Update
1. functions/services/oauthHandlers.js - Add PKCE support
2. functions/index.js - Integrate PKCE routes
3. public/index.html - Add PKCE OAuth UI
4. functions/services/llmService.js - Enhance intent parsing
5. firebase.json - Add /auth routes

