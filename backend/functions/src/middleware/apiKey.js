const { SENSOR_API_KEY } = require('../config');

function authenticateApiKey(req, res, next) {
  const apiKey = req.headers['x-api-key'] || req.body?.api_key;

  if (!apiKey) {
    return res.status(401).json({ error: 'API key is required' });
  }

  if (apiKey !== SENSOR_API_KEY) {
    return res.status(403).json({ error: 'Invalid API key' });
  }

  next();
}

module.exports = { authenticateApiKey };
