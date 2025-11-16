/**
 * Vision API Service
 * Uses Google Cloud Vision API for image analysis (labels, OCR)
 */

const axios = require('axios');
const functions = require('firebase-functions');

class VisionService {
  constructor() {
    // Try Vision-specific key first, then fallback to Google Maps key (same project, might work)
    this.apiKey = process.env.GOOGLE_VISION_KEY || 
      process.env.GOOGLE_VISION_API_KEY ||
      (typeof functions !== 'undefined' && functions.config().vision?.key) ||
      // Fallback: Try using Google Maps API key (if Vision API is enabled in same project)
      (typeof functions !== 'undefined' && functions.config().google?.maps_key);
  }

  /**
   * Analyze image using Google Vision API
   * @param {string} imageBase64 - Base64 encoded image (with or without data URL prefix)
   * @returns {Promise<{labels: string[], ocr: string, error?: string}>}
   */
  async analyzeImage(imageBase64) {
    if (!imageBase64) {
      return { error: 'No image provided', labels: [], ocr: '' };
    }

    if (!this.apiKey) {
      console.warn('[Vision] Google Vision API key not configured');
      return { 
        mock: true, 
        msg: 'No GOOGLE_VISION_KEY set', 
        labels: [], 
        ocr: '' 
      };
    }

    try {
      // Remove data URL prefix if present
      const imageContent = imageBase64.includes(',') 
        ? imageBase64.split(',').pop() 
        : imageBase64;

      const url = `https://vision.googleapis.com/v1/images:annotate?key=${this.apiKey}`;
      const body = {
        requests: [{
          image: { content: imageContent },
          features: [
            { type: 'LABEL_DETECTION', maxResults: 10 },
            { type: 'TEXT_DETECTION', maxResults: 5 }
          ]
        }]
      };

      const response = await axios.post(url, body, { timeout: 15000 });
      const result = response.data.responses[0] || {};

      const labels = (result.labelAnnotations || []).map(l => l.description);
      const ocr = result.textAnnotations && result.textAnnotations.length > 0
        ? result.textAnnotations[0].description
        : '';

      return { labels, ocr };
    } catch (error) {
      console.error('[Vision] API error:', error.message);
      return { 
        error: error.message, 
        labels: [], 
        ocr: '' 
      };
    }
  }

  /**
   * Extract text from image (OCR)
   */
  async extractText(imageBase64) {
    const result = await this.analyzeImage(imageBase64);
    return result.ocr || '';
  }

  /**
   * Get labels/descriptions from image
   */
  async getLabels(imageBase64) {
    const result = await this.analyzeImage(imageBase64);
    return result.labels || [];
  }
}

module.exports = { VisionService };

