const { auth } = require('../services/firebase');
const { SENSOR_API_KEY } = require('../config');

async function authenticateTokenOrApiKey(req, res, next) {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split('Bearer ')[1];
    try {
      const decodedToken = await auth.verifyIdToken(token);
      req.user = decodedToken;
      return next();
    } catch (error) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }
  }

  const apiKey = req.headers['x-api-key'] || req.body?.api_key;
  if (apiKey && apiKey === SENSOR_API_KEY) {
    req.user = { role: 'admin', uid: 'sensor-api-key' };
    return next();
  }

  return res.status(401).json({ error: 'Authentication required. Provide a valid JWT or API key.' });
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
}

module.exports = {
  authenticateTokenOrApiKey,
  requireRole,
};
