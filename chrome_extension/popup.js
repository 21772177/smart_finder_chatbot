// popup.js - Handles popup UI interactions

document.addEventListener('DOMContentLoaded', async () => {
  const statusDiv = document.getElementById('status');
  const autoSaveToggle = document.getElementById('autoSaveToggle');
  const syncNowBtn = document.getElementById('syncNow');
  const openChatbotBtn = document.getElementById('openChatbot');
  
  // Load settings
  async function loadSettings() {
    try {
      const response = await chrome.runtime.sendMessage({ type: 'getSettings' });
      if (response && response.success) {
        const { enabled, autoSave, savedLinks } = response.settings;
        
        // Update status
        if (enabled) {
          statusDiv.className = 'status enabled';
          statusDiv.textContent = `✅ Enabled - ${savedLinks?.length || 0} links saved`;
        } else {
          statusDiv.className = 'status disabled';
          statusDiv.textContent = '❌ Disabled';
        }
        
        // Update toggle
        autoSaveToggle.checked = autoSave !== false;
      }
    } catch (error) {
      console.error('Error loading settings:', error);
      statusDiv.className = 'status disabled';
      statusDiv.textContent = 'Error loading settings';
    }
  }
  
  // Toggle auto-save
  autoSaveToggle.addEventListener('change', async (e) => {
    const enabled = e.target.checked;
    await chrome.storage.local.set({ autoSave: enabled });
    await loadSettings();
  });
  
  // Sync now button
  syncNowBtn.addEventListener('click', async () => {
    syncNowBtn.disabled = true;
    syncNowBtn.textContent = 'Syncing...';
    
    try {
      // Get saved links
      const { savedLinks } = await chrome.storage.local.get(['savedLinks']);
      
      if (!savedLinks || savedLinks.length === 0) {
        statusDiv.textContent = 'No links to sync';
        syncNowBtn.disabled = false;
        syncNowBtn.textContent = 'Sync Now';
        return;
      }
      
      // Sync to backend
      const { userId, deviceToken } = await chrome.storage.local.get(['userId', 'deviceToken']);
      
      if (!userId && !deviceToken) {
        statusDiv.textContent = 'Please connect your account in the chatbot first';
        syncNowBtn.disabled = false;
        syncNowBtn.textContent = 'Sync Now';
        return;
      }
      
      const response = await fetch('https://us-central1-buildkit-1695f.cloudfunctions.net/api/api/sync-links', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          userId: userId,
          token: deviceToken,
          links: savedLinks
        })
      });
      
      if (response.ok) {
        const result = await response.json();
        // Clear saved links after successful sync
        await chrome.storage.local.set({ savedLinks: [] });
        statusDiv.textContent = `✅ Synced ${result.count || savedLinks.length} links`;
      } else {
        throw new Error('Sync failed');
      }
    } catch (error) {
      console.error('Sync error:', error);
      statusDiv.textContent = 'Sync failed. Links saved locally.';
    } finally {
      syncNowBtn.disabled = false;
      syncNowBtn.textContent = 'Sync Now';
      setTimeout(loadSettings, 1000);
    }
  });
  
  // Open chatbot button
  openChatbotBtn.addEventListener('click', () => {
    chrome.tabs.create({ url: 'https://buildkit-1695f.web.app' });
  });
  
  // Initial load
  await loadSettings();
  
  // Refresh every 5 seconds
  setInterval(loadSettings, 5000);
});

