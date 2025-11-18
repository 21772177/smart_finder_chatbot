/**
 * Auto-Sync Scheduler
 * Periodically syncs content from connected platforms for all users
 * Runs every hour via Firebase Functions scheduled trigger
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Lazy load services to avoid initialization timeout
let syncAllPlatformContent, logError;
let db;

function getServices() {
  if (!syncAllPlatformContent) {
    syncAllPlatformContent = require('../services/contentSync').syncAllPlatformContent;
    logError = require('../services/debugLogger').logError;
  }
  return { syncAllPlatformContent, logError };
}

function getDb() {
  if (!db) {
    if (!admin.apps.length) {
      admin.initializeApp();
    }
    db = admin.firestore();
  }
  return db;
}

/**
 * Scheduled function to auto-sync content for all users
 * Runs every hour (configurable via Firebase Console)
 */
exports.autoSyncAllUsers = functions.pubsub
  .schedule('every 1 hours')
  .timeZone('UTC')
  .onRun(async (context) => {
    console.log('[Auto-Sync] Starting scheduled sync for all users...');
    
    const { syncAllPlatformContent, logError } = getServices();
    const db = getDb();
    
    try {
      // Get all users with connected platforms
      const usersSnapshot = await db.collection('users')
        .where('platforms', '!=', null)
        .limit(100) // Process 100 users at a time to avoid timeout
        .get();
      
      if (usersSnapshot.empty) {
        console.log('[Auto-Sync] No users with connected platforms found');
        return null;
      }
      
      console.log(`[Auto-Sync] Found ${usersSnapshot.size} users with connected platforms`);
      
      const syncPromises = [];
      let successCount = 0;
      let errorCount = 0;
      
      // Process each user
      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const platforms = userData.platforms || {};
        const tokens = userData.tokens || {};
        
        // Get connected platforms
        const connectedPlatforms = Object.keys(platforms).filter(
          platform => platforms[platform]?.connected === true
        );
        
        if (connectedPlatforms.length === 0) {
          continue;
        }
        
        console.log(`[Auto-Sync] Processing user ${userId} with platforms: ${connectedPlatforms.join(', ')}`);
        
        // Sync each connected platform
        for (const platform of connectedPlatforms) {
          const accessToken = tokens[platform];
          
          if (!accessToken) {
            console.warn(`[Auto-Sync] User ${userId} has ${platform} connected but no token`);
            continue;
          }
          
          // Add sync task to queue
          syncPromises.push(
            syncAllPlatformContent(userId, platform, accessToken)
              .then(result => {
                if (result.success) {
                  successCount++;
                  console.log(`[Auto-Sync] ✅ User ${userId} - ${platform}: ${result.itemsIndexed} items indexed`);
                } else {
                  errorCount++;
                  console.error(`[Auto-Sync] ❌ User ${userId} - ${platform}: ${result.error}`);
                }
                return result;
              })
              .catch(error => {
                errorCount++;
                console.error(`[Auto-Sync] ❌ User ${userId} - ${platform} error:`, error);
                logError(error, { userId, platform, scheduled: true }, userId);
                return { success: false, error: error.message };
              })
          );
        }
      }
      
      // Wait for all syncs to complete (with timeout)
      const results = await Promise.allSettled(syncPromises);
      
      const summary = {
        totalUsers: usersSnapshot.size,
        totalSyncs: syncPromises.length,
        successful: successCount,
        failed: errorCount,
        timestamp: new Date().toISOString()
      };
      
      console.log('[Auto-Sync] Summary:', summary);
      
      // Log summary to Firestore
      await db.collection('sync_logs').add({
        type: 'scheduled_sync',
        summary: summary,
        timestamp: admin.firestore.FieldValue.serverTimestamp()
      });
      
      return summary;
      
    } catch (error) {
      console.error('[Auto-Sync] Fatal error:', error);
      await logError(error, { scheduled: true, type: 'auto_sync' }, 'system');
      throw error;
    }
  });

/**
 * Alternative: Sync specific user (can be called manually)
 */
exports.autoSyncUser = functions.https.onCall(async (data, context) => {
  // Require authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const userId = context.auth.uid || data.userId;
  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'userId is required');
  }
  
  const { syncAllPlatformContent } = getServices();
  const db = getDb();
  
  try {
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }
    
    const userData = userDoc.data();
    const platforms = userData.platforms || {};
    const tokens = userData.tokens || {};
    
    const connectedPlatforms = Object.keys(platforms).filter(
      platform => platforms[platform]?.connected === true
    );
    
    if (connectedPlatforms.length === 0) {
      return { success: true, message: 'No connected platforms to sync' };
    }
    
    const results = {};
    
    for (const platform of connectedPlatforms) {
      const accessToken = tokens[platform];
      if (accessToken) {
        const result = await syncAllPlatformContent(userId, platform, accessToken);
        results[platform] = result;
      }
    }
    
    return {
      success: true,
      platforms: results,
      message: `Synced ${connectedPlatforms.length} platform(s)`
    };
    
  } catch (error) {
    console.error('[Auto-Sync] User sync error:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});

