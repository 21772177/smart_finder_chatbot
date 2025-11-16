/**
 * RAG (Retrieval Augmented Generation) Service
 * Uses Firestore as vector store for content indexing and retrieval
 */

const admin = require('firebase-admin');

// Lazy initialization of Firestore
function getDb() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.firestore();
}

const { generateEmbedding } = require('./llmService');

/**
 * Index content in Firestore with embeddings for RAG
 */
async function indexContent(content, userId, platform) {
  try {
    const db = getDb();
    // Generate embedding for the content
    const textToEmbed = `${content.title || content.caption || content.message} ${content.description || ''}`;
    const embedding = await generateEmbedding(textToEmbed);

    if (!embedding) {
      // Fallback: store without embedding
      await db.collection('content_index').add({
        userId,
        platform,
        content: content,
        text: textToEmbed,
        keywords: extractKeywords(textToEmbed),
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        indexed: false
      });
      return;
    }

    // Store with embedding
    await db.collection('content_index').add({
      userId,
      platform,
      content: content,
      text: textToEmbed,
      embedding: embedding,
      keywords: extractKeywords(textToEmbed),
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      indexed: true
    });
  } catch (error) {
    console.error('Error indexing content:', error);
  }
}

/**
 * Search indexed content using RAG
 */
async function searchContent(query, userId, platforms = [], limit = 20) {
  try {
    const db = getDb();
    // Generate query embedding
    const queryEmbedding = await generateEmbedding(query);
    const queryKeywords = extractKeywords(query);

    let queryRef = db.collection('content_index')
      .where('userId', '==', userId);

    // Filter by platforms if specified
    if (platforms.length > 0) {
      queryRef = queryRef.where('platform', 'in', platforms);
    }

    // Get more results to sort in memory (avoids index requirement)
    const snapshot = await queryRef
      .limit(500) // Get more for similarity calculation and sorting
      .get();

    if (snapshot.empty) {
      return [];
    }

    // Sort by timestamp in memory (descending) before processing
    const sortedDocs = snapshot.docs.sort((a, b) => {
      const timeA = a.data().timestamp?.seconds || a.data().timestamp?._seconds || 0;
      const timeB = b.data().timestamp?.seconds || b.data().timestamp?._seconds || 0;
      return timeB - timeA; // Descending
    });

    const results = [];

    for (const doc of sortedDocs) {
      const data = doc.data();
      let score = 0;

      // Keyword matching (fast)
      const keywordMatches = queryKeywords.filter(kw => 
        data.keywords.some(k => k.toLowerCase().includes(kw.toLowerCase()))
      ).length;
      score += keywordMatches * 0.3;

      // Text matching
      const textLower = data.text.toLowerCase();
      const queryLower = query.toLowerCase();
      if (textLower.includes(queryLower)) {
        score += 0.5;
      }

      // Embedding similarity (if available)
      if (queryEmbedding && data.embedding) {
        const similarity = cosineSimilarity(queryEmbedding, data.embedding);
        score += similarity * 0.2;
      }

      if (score > 0.1) {
        results.push({
          ...data.content,
          score: score,
          _docId: doc.id
        });
      }
    }

    // Sort by score and return top results
    return results
      .sort((a, b) => b.score - a.score)
      .slice(0, limit)
      .map(r => {
        delete r.score;
        delete r._docId;
        return r;
      });
  } catch (error) {
    console.error('RAG search error:', error);
    return [];
  }
}

/**
 * Calculate cosine similarity between two vectors
 */
function cosineSimilarity(vecA, vecB) {
  if (vecA.length !== vecB.length) return 0;

  let dotProduct = 0;
  let normA = 0;
  let normB = 0;

  for (let i = 0; i < vecA.length; i++) {
    dotProduct += vecA[i] * vecB[i];
    normA += vecA[i] * vecA[i];
    normB += vecB[i] * vecB[i];
  }

  if (normA === 0 || normB === 0) return 0;
  return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
}

/**
 * Extract keywords from text
 */
function extractKeywords(text) {
  const stopWords = new Set(['the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should', 'could', 'may', 'might', 'must', 'can']);
  
  return text
    .toLowerCase()
    .replace(/[^\w\s]/g, ' ')
    .split(/\s+/)
    .filter(word => word.length > 2 && !stopWords.has(word))
    .slice(0, 10); // Top 10 keywords
}

/**
 * Sync content from platforms to Firestore index
 */
async function syncPlatformContent(userId, platform, contentList) {
  try {
    console.log(`[Indexing] Starting to index ${contentList.length} items for platform ${platform}, user ${userId}`);
    
    if (!contentList || contentList.length === 0) {
      console.log(`[Indexing] ⚠️ No content to index (empty array)`);
      return { success: true, indexed: 0 };
    }
    
    const db = getDb();
    let batch = db.batch();
    let count = 0;
    const batchSize = 500;
    let errorCount = 0;

    for (let i = 0; i < contentList.length; i++) {
      const content = contentList[i];
      try {
        const textToEmbed = `${content.title || content.caption || content.message} ${content.description || ''}`;
        
        if (!textToEmbed.trim()) {
          console.warn(`[Indexing] ⚠️ Skipping item ${i + 1}: No text content (id: ${content.id || 'unknown'})`);
          continue;
        }
        
        console.log(`[Indexing] Processing item ${i + 1}/${contentList.length}: "${content.title || content.caption || 'no title'}"`);
        
        let embedding = null;
        try {
          embedding = await generateEmbedding(textToEmbed);
          if (!embedding) {
            console.warn(`[Indexing] ⚠️ No embedding generated for item ${i + 1}, will index without embedding`);
          }
        } catch (embedError) {
          console.error(`[Indexing] ❌ Embedding generation failed for item ${i + 1}:`, embedError.message);
          // Continue without embedding - content will still be indexed
        }

        const docRef = db.collection('content_index').doc();
        batch.set(docRef, {
          userId,
          platform,
          content: content,
          text: textToEmbed,
          embedding: embedding || null,
          keywords: extractKeywords(textToEmbed),
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          indexed: !!embedding
        });

        count++;
        if (count % batchSize === 0) {
          console.log(`[Indexing] Committing batch of ${batchSize} items (total indexed so far: ${count})`);
          await batch.commit();
          batch = db.batch();
        }
      } catch (itemError) {
        errorCount++;
        console.error(`[Indexing] ❌ Error indexing item ${i + 1}:`, itemError.message);
        // Continue with next item
      }
    }

    // Commit remaining items
    if (count % batchSize !== 0) {
      console.log(`[Indexing] Committing final batch of ${count % batchSize} items (total indexed: ${count})`);
      await batch.commit();
    }

    console.log(`[Indexing] ✅ Complete: Indexed ${count} items, ${errorCount} errors`);
    return { success: true, indexed: count, errors: errorCount };
  } catch (error) {
    console.error('[Indexing] ❌ Fatal sync error:', error);
    console.error('[Indexing] Error stack:', error.stack);
    return { success: false, error: error.message, indexed: 0 };
  }
}

module.exports = {
  indexContent,
  searchContent,
  syncPlatformContent
};

