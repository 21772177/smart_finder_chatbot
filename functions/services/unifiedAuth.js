/**
 * Unified Authentication Service
 * Uses email/mobile as common identifier to connect all platforms
 * Streamlines OAuth flow for multiple platforms
 */

const admin = require('firebase-admin');

// Lazy initialization of Firestore
function getDb() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
}

/**
 * Get or create user by email/mobile
 */
async function getOrCreateUser(identifier, type = 'email') {
  try {
    const db = getDb();
    const userRef = db.collection('users').doc(identifier);
    const userDoc = await userRef.get();
    
    if (userDoc.exists) {
      return { userId: identifier, exists: true, data: userDoc.data() };
    }
    
    // Create new user
    await userRef.set({
      identifier: identifier,
      type: type, // 'email' or 'mobile'
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      platforms: {},
      tokens: {}
    });
    
    return { userId: identifier, exists: false, data: {} };
  } catch (error) {
    console.error('Error getting/creating user:', error);
    throw error;
  }
}

/**
 * Link platform OAuth token to user
 */
async function linkPlatformToken(userId, platform, token, platformUserId = null) {
  try {
    const db = getDb();
    const userRef = db.collection('users').doc(userId);
    
    await userRef.update({
      [`tokens.${platform}`]: token,
      [`platforms.${platform}`]: {
        connected: true,
        connectedAt: admin.firestore.FieldValue.serverTimestamp(),
        platformUserId: platformUserId
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true };
  } catch (error) {
    console.error(`Error linking ${platform} token:`, error);
    throw error;
  }
}

/**
 * Get all user tokens by identifier (email/mobile)
 */
async function getUserTokensByIdentifier(identifier) {
  try {
    const db = getDb();
    const userRef = db.collection('users').doc(identifier);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      return { youtube: null, instagram: null, facebook: null };
    }
    
    const data = userDoc.data();
    return {
      youtube: data.tokens?.youtube || null,
      instagram: data.tokens?.instagram || null,
      facebook: data.tokens?.facebook || null,
      userId: identifier,
      platforms: data.platforms || {}
    };
  } catch (error) {
    console.error('Error getting user tokens:', error);
    return { youtube: null, instagram: null, facebook: null };
  }
}

/**
 * Check which platforms are connected for a user
 */
async function getConnectedPlatforms(userId) {
  try {
    const db = getDb();
    const userRef = db.collection('users').doc(userId);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      return { connected: [], disconnected: ['youtube', 'instagram', 'facebook'] };
    }
    
    const data = userDoc.data();
    const platforms = data.platforms || {};
    const connected = [];
    const disconnected = [];
    
    ['youtube', 'instagram', 'facebook'].forEach(platform => {
      if (platforms[platform]?.connected && data.tokens?.[platform]) {
        connected.push(platform);
      } else {
        disconnected.push(platform);
      }
    });
    
    return { connected, disconnected };
  } catch (error) {
    console.error('Error getting connected platforms:', error);
    return { connected: [], disconnected: ['youtube', 'instagram', 'facebook'] };
  }
}

/**
 * Unified OAuth consent - user gives consent to connect all platforms
 */
async function recordUnifiedConsent(userId, platforms = ['youtube', 'instagram', 'facebook']) {
  try {
    const db = getDb();
    const userRef = db.collection('users').doc(userId);
    
    await userRef.update({
      unifiedConsent: {
        granted: true,
        platforms: platforms,
        grantedAt: admin.firestore.FieldValue.serverTimestamp(),
        consentText: 'User has given consent to connect and search across all platforms'
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error recording unified consent:', error);
    throw error;
  }
}

module.exports = {
  getOrCreateUser,
  linkPlatformToken,
  getUserTokensByIdentifier,
  getConnectedPlatforms,
  recordUnifiedConsent
};

