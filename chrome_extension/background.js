// background.js - Service worker for Smart Finder Chrome Extension
// Listens for user opt-in and schedules periodic scans

const BACKEND_URL = 'https://us-central1-buildkit-1695f.cloudfunctions.net/api';
const CHATBOT_URL = 'https://buildkit-1695f.web.app';

// Initialize on install
chrome.runtime.onInstalled.addListener(() => {
  console.log('Smart Finder AutoSave extension installed');
  
  // Create alarm for periodic sync (every 30 minutes)
  chrome.alarms.create('autoscan', { periodInMinutes: 30 });
  
  // Set default settings
  chrome.storage.local.set({
    enabled: true,
    autoSave: true,
    userId: null,
    deviceToken: null
  });
});

// Handle alarm events
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'autoscan') {
    console.log('[AutoSave] Periodic scan triggered');
    scanActiveTabs();
  }
});

// Scan active tabs for YouTube/Instagram/Facebook
async function scanActiveTabs() {
  try {
    const settings = await chrome.storage.local.get(['enabled', 'autoSave']);
    
    if (!settings.enabled || !settings.autoSave) {
      console.log('[AutoSave] Auto-save disabled, skipping scan');
      return;
    }
    
    const tabs = await chrome.tabs.query({});
    const relevantTabs = tabs.filter(t => 
      t.url && (
        t.url.includes('youtube.com') || 
        t.url.includes('youtu.be') ||
        t.url.includes('instagram.com') ||
        t.url.includes('facebook.com')
      )
    );
    
    console.log(`[AutoSave] Found ${relevantTabs.length} relevant tabs`);
    
    for (const tab of relevantTabs) {
      try {
        // Inject content script to extract link
        await chrome.scripting.executeScript({
          target: { tabId: tab.id },
          files: ['content.js']
        });
      } catch (error) {
        console.warn(`[AutoSave] Could not inject script into tab ${tab.id}:`, error);
      }
    }
  } catch (error) {
    console.error('[AutoSave] Scan error:', error);
  }
}

// Listen for messages from content script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'saveLink') {
    handleSaveLink(message.link, message.metadata)
      .then(result => sendResponse({ success: true, result }))
      .catch(error => sendResponse({ success: false, error: error.message }));
    return true; // Keep channel open for async response
  } else if (message.type === 'getSettings') {
    chrome.storage.local.get(['enabled', 'autoSave', 'userId', 'deviceToken'])
      .then(settings => sendResponse({ success: true, settings }));
    return true;
  }
  return false;
});

// Handle link saving
async function handleSaveLink(url, metadata = {}) {
  try {
    const settings = await chrome.storage.local.get(['userId', 'deviceToken', 'enabled']);
    
    if (!settings.enabled) {
      console.log('[AutoSave] Extension disabled, not saving link');
      return { saved: false, reason: 'Extension disabled' };
    }
    
    // Store link locally first
    const savedLinks = await chrome.storage.local.get(['savedLinks']);
    const links = savedLinks.savedLinks || [];
    
    // Check if link already exists
    if (links.some(l => l.url === url)) {
      console.log('[AutoSave] Link already saved:', url);
      return { saved: false, reason: 'Already saved' };
    }
    
    const linkData = {
      url: url,
      metadata: metadata,
      timestamp: new Date().toISOString(),
      platform: detectPlatform(url)
    };
    
    links.push(linkData);
    await chrome.storage.local.set({ savedLinks: links });
    
    console.log('[AutoSave] Link saved locally:', url);
    
    // Sync to backend if user is authenticated
    if (settings.userId || settings.deviceToken) {
      try {
        await syncLinkToBackend(linkData, settings);
        console.log('[AutoSave] Link synced to backend');
      } catch (error) {
        console.warn('[AutoSave] Backend sync failed:', error);
        // Link is still saved locally, will retry later
      }
    }
    
    return { saved: true, link: linkData };
  } catch (error) {
    console.error('[AutoSave] Save link error:', error);
    throw error;
  }
}

// Sync link to backend
async function syncLinkToBackend(linkData, settings) {
  const identifier = settings.userId || settings.deviceToken;
  
  if (!identifier) {
    return; // No user identifier, skip backend sync
  }
  
  try {
    const response = await fetch(`${BACKEND_URL}/api/sync-links`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        userId: settings.userId,
        token: settings.deviceToken,
        links: [linkData]
      })
    });
    
    if (!response.ok) {
      throw new Error(`Backend sync failed: ${response.status}`);
    }
    
    const result = await response.json();
    return result;
  } catch (error) {
    console.error('[AutoSave] Backend sync error:', error);
    throw error;
  }
}

// Detect platform from URL
function detectPlatform(url) {
  if (url.includes('youtube.com') || url.includes('youtu.be')) {
    return 'youtube';
  } else if (url.includes('instagram.com')) {
    return 'instagram';
  } else if (url.includes('facebook.com')) {
    return 'facebook';
  }
  return 'unknown';
}

// Sync all saved links to backend (manual trigger)
async function syncAllLinks() {
  try {
    const settings = await chrome.storage.local.get(['userId', 'deviceToken', 'savedLinks']);
    const links = settings.savedLinks || [];
    
    if (links.length === 0) {
      return { synced: 0, message: 'No links to sync' };
    }
    
    const result = await syncLinkToBackend({ links }, settings);
    
    // Clear local links after successful sync
    if (result && result.success) {
      await chrome.storage.local.set({ savedLinks: [] });
    }
    
    return { synced: links.length, result };
  } catch (error) {
    console.error('[AutoSave] Sync all links error:', error);
    throw error;
  }
}

// Export for popup
if (typeof window !== 'undefined') {
  window.syncAllLinks = syncAllLinks;
}

