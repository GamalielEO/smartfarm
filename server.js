// Entry point for Render deployment
// Simply imports the main app (app.js) and starts the server

const app = require('./app');
const PORT = process.env.PORT || 3000;

// Start the server
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
