/**
 * Product Search Service (Aggregator)
 * Searches across multiple e-commerce platforms (Temu, Flipkart, Amazon, AliExpress)
 */

const axios = require('axios');
const functions = require('firebase-functions');

class ProductSearchService {
  constructor() {
    this.apifyToken = process.env.APIFY_TOKEN || 
      (typeof functions !== 'undefined' && functions.config().apify?.token);
    this.temuApi = process.env.TEMU_API || 
      (typeof functions !== 'undefined' && functions.config().temu?.api);
    this.flipkartApi = process.env.FLIPKART_API || 
      (typeof functions !== 'undefined' && functions.config().flipkart?.api);
    this.amazonApi = process.env.AMAZON_API || 
      (typeof functions !== 'undefined' && functions.config().amazon?.api);
  }

  /**
   * Search products across all platforms
   */
  async searchProducts(query, maxResults = 40) {
    const tokens = query.split(' ').filter(t => t.length > 0);
    if (tokens.length === 0) {
      return [];
    }

    const results = [];
    
    // Search all platforms in parallel
    const promises = [
      this.searchTemu(tokens),
      this.searchFlipkart(tokens),
      this.searchAmazon(tokens),
      this.searchAliExpress(tokens)
    ];

    const platformResults = await Promise.allSettled(promises);
    
    platformResults.forEach((result, index) => {
      if (result.status === 'fulfilled' && Array.isArray(result.value)) {
        results.push(...result.value);
      }
    });

    // Deduplicate and limit results
    const seen = new Set();
    const merged = [];
    
    for (const r of results) {
      const key = (r.link || r.title || '').toString().slice(0, 200);
      if (seen.has(key)) continue;
      seen.add(key);
      merged.push(r);
      if (merged.length >= maxResults) break;
    }

    return merged;
  }

  /**
   * Search Temu
   */
  async searchTemu(tokens) {
    if (!this.temuApi) {
      console.warn('[Product Search] Temu API not configured');
      return [];
    }

    try {
      const query = encodeURIComponent(tokens.join(' '));
      const url = `${this.temuApi}/search?q=${query}`;
      const response = await axios.get(url, { timeout: 10000 });
      return (response.data.items || []).map(item => ({
        platform: 'Temu',
        title: item.title || item.name,
        price: item.price,
        currency: item.currency || 'USD',
        link: item.link || item.url,
        image: item.image || item.thumbnail,
        shipping_days: item.shipping_days || 7,
        origin: item.origin || 'China',
        stock_status: item.stock_status || 'in_stock',
        seller_verified: item.seller_verified || false
      }));
    } catch (error) {
      console.error('[Product Search] Temu error:', error.message);
      return [];
    }
  }

  /**
   * Search Flipkart
   */
  async searchFlipkart(tokens) {
    if (!this.flipkartApi) {
      console.warn('[Product Search] Flipkart API not configured');
      return [];
    }

    try {
      const query = encodeURIComponent(tokens.join(' '));
      const url = `${this.flipkartApi}/search?q=${query}`;
      const response = await axios.get(url, { timeout: 10000 });
      return (response.data.items || []).map(item => ({
        platform: 'Flipkart',
        title: item.title || item.name,
        price: item.price,
        currency: item.currency || 'INR',
        link: item.link || item.url,
        image: item.image || item.thumbnail,
        shipping_days: item.shipping_days || 3,
        origin: item.origin || 'India',
        stock_status: item.stock_status || 'in_stock',
        seller_verified: item.seller_verified || false
      }));
    } catch (error) {
      console.error('[Product Search] Flipkart error:', error.message);
      return [];
    }
  }

  /**
   * Search Amazon
   */
  async searchAmazon(tokens) {
    // Placeholder - implement when API is available
    console.warn('[Product Search] Amazon API not implemented yet');
    return [];
  }

  /**
   * Search AliExpress via Apify
   */
  async searchAliExpress(tokens) {
    if (!this.apifyToken) {
      console.warn('[Product Search] Apify token not configured');
      return [];
    }

    // Placeholder - implement Apify scraper when needed
    console.warn('[Product Search] AliExpress via Apify not implemented yet');
    return [];
  }

  /**
   * Verify and score product listings
   */
  verifyListings(listings) {
    function computeScore(listing) {
      let score = 0;
      if (listing.stock_status === 'in_stock') score += 50;
      if (listing.seller_verified) score += 30;
      score += Math.max(0, 20 - (listing.shipping_days || 20));
      if (listing.origin && listing.origin.toLowerCase().includes('india')) {
        score += 10;
      }
      return score;
    }

    return listings.map(listing => ({
      platform: listing.platform || 'Unknown',
      title: listing.title || listing.name || 'Unknown product',
      price: listing.price || null,
      currency: listing.currency || 'INR',
      shipping_days: listing.shipping_days || 7,
      link: listing.link || '#',
      origin: listing.origin || 'Unknown',
      stock_status: listing.stock_status || 'unknown',
      seller_verified: !!listing.seller_verified,
      availability_label: listing.stock_status === 'in_stock' 
        ? '✅ Available' 
        : (listing.stock_status === 'low_stock' ? '⚠️ Low Stock' : '❌ Out of Stock'),
      score: computeScore(listing)
    })).sort((a, b) => b.score - a.score); // Sort by score descending
  }
}

module.exports = { ProductSearchService };

