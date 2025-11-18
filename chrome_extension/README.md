# Smart Finder Chrome Extension

Chrome extension for automatically saving YouTube, Instagram, and Facebook links to Smart Finder chatbot.

## Features

- ✅ Auto-save links from YouTube, Instagram, and Facebook
- ✅ Manual save with keyboard shortcut (Ctrl+Shift+S / Cmd+Shift+S)
- ✅ Periodic sync to backend
- ✅ Local storage for offline support
- ✅ Simple popup interface

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `chrome_extension` folder
5. Extension is now installed!

## Usage

### Auto-Save
- Extension automatically saves links when you visit YouTube, Instagram, or Facebook pages
- Toggle auto-save on/off in the popup

### Manual Save
- Press `Ctrl+Shift+S` (or `Cmd+Shift+S` on Mac) to save current page
- Or click the extension icon and click "Sync Now"

### Sync to Backend
1. Open the chatbot: https://buildkit-1695f.web.app
2. Connect your account (get device token)
3. Open extension popup
4. Click "Sync Now" to sync all saved links

## Configuration

The extension stores:
- `enabled`: Whether extension is enabled
- `autoSave`: Whether to auto-save links
- `userId`: Your user ID (from chatbot)
- `deviceToken`: Your device token (from chatbot)
- `savedLinks`: Array of saved links (synced to backend)

## Development

### Files
- `manifest.json` - Extension configuration
- `background.js` - Service worker (handles link saving, sync)
- `content.js` - Content script (extracts links from pages)
- `popup.html` - Popup UI
- `popup.js` - Popup logic

### Testing
1. Load extension in Chrome
2. Visit a YouTube/Instagram/Facebook page
3. Check extension popup for saved links
4. Test sync functionality

## Notes

- Links are saved locally first, then synced to backend
- Requires user to be logged in to chatbot for backend sync
- Works offline (saves locally, syncs when online)

