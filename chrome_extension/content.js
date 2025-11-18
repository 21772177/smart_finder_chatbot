// content.js - Extracts current video/post link and sends to background
// Runs on YouTube, Instagram, and Facebook pages

(function() {
  'use strict';
  
  // Prevent multiple injections
  if (window.smartFinderInjected) {
    return;
  }
  window.smartFinderInjected = true;
  
  // Detect platform
  const platform = detectPlatform();
  
  // Extract link and metadata
  function extractLinkAndMetadata() {
    const url = window.location.href;
    const metadata = {
      url: url,
      title: document.title,
      timestamp: new Date().toISOString()
    };
    
    if (platform === 'youtube') {
      // Extract YouTube video metadata
      const videoId = getYouTubeVideoId(url);
      if (videoId) {
        metadata.videoId = videoId;
        metadata.type = 'video';
        
        // Try to get video title
        const titleElement = document.querySelector('h1.ytd-watch-metadata yt-formatted-string, h1.title');
        if (titleElement) {
          metadata.title = titleElement.textContent.trim();
        }
        
        // Try to get channel name
        const channelElement = document.querySelector('#channel-name a, ytd-channel-name a');
        if (channelElement) {
          metadata.channel = channelElement.textContent.trim();
        }
        
        // Try to get thumbnail
        const thumbnailElement = document.querySelector('meta[property="og:image"]');
        if (thumbnailElement) {
          metadata.thumbnail = thumbnailElement.content;
        }
      }
    } else if (platform === 'instagram') {
      // Extract Instagram post metadata
      metadata.type = 'post';
      
      // Try to get post description
      const descElement = document.querySelector('meta[property="og:description"]');
      if (descElement) {
        metadata.description = descElement.content;
      }
      
      // Try to get image
      const imageElement = document.querySelector('meta[property="og:image"]');
      if (imageElement) {
        metadata.thumbnail = imageElement.content;
      }
    } else if (platform === 'facebook') {
      // Extract Facebook post metadata
      metadata.type = 'post';
      
      // Try to get post text
      const textElement = document.querySelector('[data-testid="post_message"]');
      if (textElement) {
        metadata.description = textElement.textContent.trim();
      }
      
      // Try to get image
      const imageElement = document.querySelector('meta[property="og:image"]');
      if (imageElement) {
        metadata.thumbnail = imageElement.content;
      }
    }
    
    return { url, metadata };
  }
  
  // Get YouTube video ID from URL
  function getYouTubeVideoId(url) {
    const patterns = [
      /(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)/,
      /youtube\.com\/embed\/([^&\n?#]+)/,
      /youtube\.com\/v\/([^&\n?#]+)/
    ];
    
    for (const pattern of patterns) {
      const match = url.match(pattern);
      if (match) {
        return match[1];
      }
    }
    
    return null;
  }
  
  // Detect current platform
  function detectPlatform() {
    const hostname = window.location.hostname;
    if (hostname.includes('youtube.com') || hostname.includes('youtu.be')) {
      return 'youtube';
    } else if (hostname.includes('instagram.com')) {
      return 'instagram';
    } else if (hostname.includes('facebook.com')) {
      return 'facebook';
    }
    return 'unknown';
  }
  
  // Send link to background script
  function saveCurrentLink() {
    const { url, metadata } = extractLinkAndMetadata();
    
    chrome.runtime.sendMessage({
      type: 'saveLink',
      link: url,
      metadata: metadata
    }, (response) => {
      if (response && response.success) {
        console.log('[Smart Finder] Link saved:', url);
        showNotification('Link saved to Smart Finder!');
      } else {
        console.warn('[Smart Finder] Failed to save link:', response);
      }
    });
  }
  
  // Show notification
  function showNotification(message) {
    // Create a simple notification element
    const notification = document.createElement('div');
    notification.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #4CAF50;
      color: white;
      padding: 15px 20px;
      border-radius: 5px;
      z-index: 10000;
      font-family: Arial, sans-serif;
      font-size: 14px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.2);
      animation: slideIn 0.3s ease;
    `;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.style.animation = 'slideOut 0.3s ease';
      setTimeout(() => notification.remove(), 300);
    }, 3000);
  }
  
  // Listen for page changes (SPA navigation)
  let lastUrl = location.href;
  new MutationObserver(() => {
    const currentUrl = location.href;
    if (currentUrl !== lastUrl) {
      lastUrl = currentUrl;
      // Page changed, could auto-save if enabled
      // For now, we'll only save on explicit user action or periodic scan
    }
  }).observe(document, { subtree: true, childList: true });
  
  // Auto-save on page load (if enabled)
  chrome.runtime.sendMessage({ type: 'getSettings' }, (response) => {
    if (response && response.success && response.settings.autoSave) {
      // Small delay to ensure page is fully loaded
      setTimeout(() => {
        saveCurrentLink();
      }, 2000);
    }
  });
  
  // Listen for keyboard shortcut (Ctrl+Shift+S or Cmd+Shift+S)
  document.addEventListener('keydown', (e) => {
    if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'S') {
      e.preventDefault();
      saveCurrentLink();
    }
  });
  
  console.log('[Smart Finder] Content script loaded for', platform);
})();

