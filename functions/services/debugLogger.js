/**
 * Smart Debug Logger for Testing Phase
 * Automatically logs all operations, errors, and sync status
 * No approval required - always active in testing phase
 */

const admin = require('firebase-admin');

function getDb() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
}

/**
 * Log debug information
 */
async function logDebug(category, message, data = {}, userId = 'unknown') {
  try {
    const db = getDb();
    const timestamp = admin.firestore.FieldValue.serverTimestamp();
    
    const logEntry = {
      category, // 'sync', 'query', 'oauth', 'error', 'api'
      message,
      data,
      userId,
      timestamp,
      environment: 'testing', // Always in testing mode
      autoLogged: true // No approval required
    };
    
    // Store in debug_logs collection
    await db.collection('debug_logs').add(logEntry);
    
    // Also log to console for immediate visibility
    console.log(`[${category.toUpperCase()}] ${message}`, data);
    
    return logEntry;
  } catch (error) {
    console.error('Error logging debug info:', error);
    // Fallback to console only
    console.log(`[${category.toUpperCase()}] ${message}`, data);
  }
}

/**
 * Log sync operation
 */
async function logSync(platform, userId, status, details = {}) {
  return await logDebug('sync', `Sync ${status} for ${platform}`, {
    platform,
    status, // 'started', 'completed', 'failed'
    ...details
  }, userId);
}

/**
 * Log query operation
 */
async function logQuery(userId, query, intent, resultsCount, details = {}) {
  return await logDebug('query', `Query processed`, {
    query,
    intent,
    resultsCount,
    ...details
  }, userId);
}

/**
 * Log OAuth operation
 */
async function logOAuth(platform, userId, status, details = {}) {
  return await logDebug('oauth', `OAuth ${status} for ${platform}`, {
    platform,
    status, // 'started', 'completed', 'failed'
    ...details
  }, userId);
}

/**
 * Log error
 */
async function logError(error, context = {}, userId = 'unknown') {
  return await logDebug('error', `Error occurred: ${error.message}`, {
    error: error.message,
    stack: error.stack,
    ...context
  }, userId);
}

/**
 * Log API call
 */
async function logAPI(platform, endpoint, method, status, details = {}) {
  return await logDebug('api', `API ${method} ${endpoint} - ${status}`, {
    platform,
    endpoint,
    method,
    status,
    ...details
  });
}

/**
 * Get recent logs for a user
 */
async function getRecentLogs(userId, limit = 50) {
  try {
    const db = getDb();
    const snapshot = await db.collection('debug_logs')
      .where('userId', '==', userId)
      .orderBy('timestamp', 'desc')
      .limit(limit)
      .get();
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error getting recent logs:', error);
    return [];
  }
}

/**
 * Get sync status for a user
 */
async function getSyncStatus(userId) {
  try {
    const db = getDb();
    const syncLogs = await db.collection('debug_logs')
      .where('userId', '==', userId)
      .where('category', '==', 'sync')
      .orderBy('timestamp', 'desc')
      .limit(10)
      .get();
    
    const status = {
      youtube: { status: 'unknown', lastSync: null, itemsIndexed: 0 },
      instagram: { status: 'unknown', lastSync: null, itemsIndexed: 0 },
      facebook: { status: 'unknown', lastSync: null, itemsIndexed: 0 }
    };
    
    syncLogs.docs.forEach(doc => {
      const data = doc.data();
      const platform = data.data?.platform;
      if (platform && status[platform]) {
        status[platform].status = data.data?.status || 'unknown';
        status[platform].lastSync = data.timestamp;
        status[platform].itemsIndexed = data.data?.itemsIndexed || 0;
      }
    });
    
    return status;
  } catch (error) {
    console.error('Error getting sync status:', error);
    return null;
  }
}

/**
 * Get error summary for a user
 */
async function getErrorSummary(userId, hours = 24) {
  try {
    const db = getDb();
    const cutoffTime = new Date();
    cutoffTime.setHours(cutoffTime.getHours() - hours);
    
    const errorLogs = await db.collection('debug_logs')
      .where('userId', '==', userId)
      .where('category', '==', 'error')
      .where('timestamp', '>=', admin.firestore.Timestamp.fromDate(cutoffTime))
      .orderBy('timestamp', 'desc')
      .limit(100)
      .get();
    
    return errorLogs.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error getting error summary:', error);
    return [];
  }
}

module.exports = {
  logDebug,
  logSync,
  logQuery,
  logOAuth,
  logError,
  logAPI,
  getRecentLogs,
  getSyncStatus,
  getErrorSummary
};

