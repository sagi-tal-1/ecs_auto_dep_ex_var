const express = require('express');
const app = express();

// Get identity from environment variable
const serviceIdentity = process.env.SERVICE_IDENTITY || 'unknown';

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// Identity endpoint
app.get(`/${serviceIdentity}`, (req, res) => {
  res.json({
    identity: serviceIdentity,
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Catch-all route for any other requests
app.get('*', (req, res) => {
  res.status(404).send('Not Found');
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server ${serviceIdentity} is running on port ${PORT}`);
});
