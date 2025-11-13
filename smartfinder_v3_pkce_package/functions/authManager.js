
const crypto = require('crypto');

function base64urlencode(str) {
  return str.toString('base64').replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
}

function verifyCodeChallenge(code_verifier, code_challenge) {
  const hash = crypto.createHash('sha256').update(code_verifier).digest();
  const calc = base64urlencode(hash);
  return calc === code_challenge;
}

module.exports = { verifyCodeChallenge, base64urlencode };
