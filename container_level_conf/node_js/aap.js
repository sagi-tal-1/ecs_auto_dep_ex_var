const express = require('express');
const app = express();
const port = process.env.NODE_PORT || 3000;

const uniqueIdentity = process.env.UNIQUE_IDENTITY || 'default-identity';

app.use((req, res, next) => {
  console.log(`Received request: ${req.method} ${req.url}`);
  console.log('Headers:', req.headers);
  next();
});

app.get('/how-am-i', (req, res) => {
  console.log(`Responding with - Unique Identity: ${uniqueIdentity}`);
  res.send(`Unique Identity: ${uniqueIdentity}\n`);
});

// Add health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Node.js service listening at http://0.0.0.0:${port}`);
});