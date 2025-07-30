<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Smart Farm Dashboard</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="/styles/styles.css">
</head>
<body>
  <div class="container-fluid">
    <nav class="navbar bg-success">
      <div class="container">
        <span class="navbar-brand text-white">
          🌱 Smart Agriculture System
          <span id="connection-status" class="badge bg-info ms-2">Connecting...</span>
        </span>
        <div class="d-flex gap-2">
          <form action="/add-device" method="POST" class="d-flex gap-2">
            <input type="text" name="name" placeholder="Device Name" class="form-control" required>
            <input type="text" name="location" placeholder="Location" class="form-control">
            <button type="submit" class="btn btn-light">Add Device</button>
          </form>
        </div>
      </div>
    </nav>

    <div class="glass-card my-4">
      <form action="/add-plant" method="POST" class="row g-3 align-items-center">
        <div class="col-md-4">
          <select name="deviceId" class="form-select" required>
            <option value="">Select Device</option>
            <% devices.forEach(device => { %>
              <option value="<%= device.id %>"><%= device.name %> (<%= device.location %>)</option>
            <% }) %>
          </select>
        </div>
        <div class="col-md-4">
          <select name="plantType" class="form-select" required>
            <option value="">Select Plant</option>
            <option value="Tomato">Tomato</option>
            <option value="Lettuce">Lettuce</option>
            <option value="Pepper">Pepper</option>
            <option value="Basil">Basil</option>
            <option value="Strawberry">Strawberry</option>
          </select>
        </div>
        <div class="col-md-4">
          <button type="submit" class="btn btn-success w-100">Add Plant</button>
        </div>
      </form>
    </div>

    <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 g-4">
      <% if (devices.length === 0) { %>
        <div class="col-12">
          <div class="alert alert-info text-center">
            No devices found. Add your first device to get started.
          </div>
        </div>
      <% } %>

      <% devices.forEach(device => { %>
        <% const devicePlants = plants.filter(p => p.deviceId === device.id); %>
        
        <% if (devicePlants.length > 0) { %>
          <% devicePlants.forEach(plant => { %>
            <div class="col">
              <div class="plant-card status-<%= helpers.getStatus(plant.stats.temperature, 18, 35) %>">
                <div class="card-header d-flex justify-content-between align-items-center">
                  <h5 class="mb-0"><%= plant.type %></h5>
                  <div>
                    <span class="badge bg-primary"><%= device.name %></span>
                    <span class="badge bg-secondary"><%= device.location %></span>
                  </div>
                </div>
                <div class="card-body">
                  <div class="sensor-grid">
                    <div class="sensor-item <%= helpers.getStatus(plant.stats.temperature, 18, 35) %>">
                      <div class="sensor-value">🌡️ 
                        <%= typeof plant.stats.temperature === 'string' && plant.stats.temperature.includes('error') ? 'Error' : plant.stats.temperature %>
                        <%= isNaN(plant.stats.temperature) ? '' : '°C' %>
                      </div>
                      <div class="sensor-label">Temperature</div>
                    </div>
                    
                    <div class="sensor-item <%= helpers.getStatus(plant.stats.humidity, 40, 90) %>">
                      <div class="sensor-value">💧 
                        <%= typeof plant.stats.humidity === 'string' && plant.stats.humidity.includes('error') ? 'Error' : plant.stats.humidity %>
                        <%= isNaN(plant.stats.humidity) ? '' : '%' %>
                      </div>
                      <div class="sensor-label">Humidity</div>
                    </div>
                    
                    <div class="sensor-item <%= helpers.getStatus(plant.stats.soilMoisture, 30, 80) %>">
                      <div class="sensor-value">🌱 
                        <%= typeof plant.stats.soilMoisture === 'string' && plant.stats.soilMoisture.includes('error') ? 'Error' : plant.stats.soilMoisture %>
                        <%= isNaN(plant.stats.soilMoisture) ? '' : '%' %>
                      </div>
                      <div class="sensor-label">Soil Moisture</div>
                    </div>
                    
                    <div class="sensor-item <%= helpers.getStatus(plant.stats.lightLevel, 3000, 15000) %>">
                      <div class="sensor-value">💡 
                        <%= typeof plant.stats.lightLevel === 'string' && plant.stats.lightLevel.includes('error') ? 'Error' : plant.stats.lightLevel %>
                        <%= isNaN(plant.stats.lightLevel) ? '' : 'lux' %>
                      </div>
                      <div class="sensor-label">Light Level</div>
                    </div>
                  </div>
                  
                  <div class="recommendations mt-3">
                    <h6>🌿 AI Recommendations</h6>
                    <ul class="list-unstyled">
                      <% plant.recommendations.forEach(recommendation => { %>
                        <li>✅ <%= recommendation %></li>
                      <% }) %>
                    </ul>
                  </div>

                  <div class="text-muted small mt-2">
                    Last updated: <%= plant.stats.lastUpdated %>
                    <% if (plant.stats.lastUpdated.includes('offline')) { %>
                      <span class="badge bg-warning text-dark ms-2">Offline Mode</span>
                    <% } %>
                  </div>
                </div>
              </div>
            </div>
          <% }) %>
        <% } else { %>
          <div class="col">
            <div class="plant-card">
              <div class="card-header d-flex justify-content-between align-items-center">
                <h5 class="mb-0"><%= device.name %></h5>
                <span class="badge bg-secondary"><%= device.location %></span>
              </div>
              <div class="card-body text-center py-4">
                <p class="text-muted mb-3">No plants being monitored</p>
                <form action="/add-plant" method="POST">
                  <input type="hidden" name="deviceId" value="<%= device.id %>">
                  <button type="submit" class="btn btn-success">
                    Start Monitoring
                  </button>
                </form>
              </div>
            </div>
          </div>
        <% } %>
      <% }) %>
    </div>
  </div>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  <script>
    // Connection monitoring
    async function updateConnectionStatus() {
      const statusElement = document.getElementById('connection-status');
      try {
        const response = await fetch('/check-connection');
        const { connected } = await response.json();
        
        statusElement.textContent = connected ? 'Connected' : 'Offline';
        statusElement.className = connected 
          ? 'badge bg-success ms-2' 
          : 'badge bg-danger ms-2';
          
        if (!connected) {
          console.warn('Blynk connection lost - using fallback data');
        }
      } catch (error) {
        statusElement.textContent = 'Error';
        statusElement.className = 'badge bg-warning text-dark ms-2';
        console.error('Connection check failed:', error);
      }
    }

    // Auto-refresh and monitoring
    document.addEventListener('DOMContentLoaded', () => {
      updateConnectionStatus();
      
      // Check connection every minute
      setInterval(updateConnectionStatus, 60000);
      
      // Refresh data every 30 seconds
      setInterval(() => {
        window.location.reload();
      }, 30000);
    });
  </script>
</body>
</html>

////////////////////////////////////////////////////////////////////////////////////////////////////
const express = require('express');
const path = require('path');
const fetch = require('node-fetch');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Mock databases
let devices = [];
let plants = [];

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Blynk Configuration
const BLYNK_CONFIG = {
  BASE_URL: process.env.BLYNK_URL || 'https://ny3.blynk.cloud/external/api',
  TOKEN: process.env.BLYNK_TOKEN
};

// Helpers
const helpers = {
  // Status Checkers
  getStatus: (value, min, max) => {
    const num = parseFloat(value);
    if (num < min || num > max) return 'critical';
    if (num < min + 0.2*(max-min) || num > max - 0.2*(max-min)) return 'warning';
    return 'normal';
  },

  // Blynk Communication
  async updateBlynk(deviceId, pin, value) {
    try {
      const device = devices.find(d => d.id === deviceId);
      if (!device) return false;
      
      const response = await fetch(
        `${BLYNK_CONFIG.BASE_URL}/update?token=${BLYNK_CONFIG.TOKEN}&${pin}=${value}`
      );
      return response.ok;
    } catch (error) {
      console.error('Blynk update failed:', error);
      return false;
    }
  },

  // Device Management
  createVirtualPins: () => {
    const startingPin = devices.length * 6;
    return {
      soilTemp: `v${startingPin}`,
      soilMoisture: `v${startingPin + 1}`,
      airTemp: `v${startingPin + 2}`,
      airHumidity: `v${startingPin + 3}`,
      aiComms: `v${startingPin + 4}`,
      light: `v${startingPin + 5}`
    };
  }
};

// Generate mock sensor data
const getMockSensorData = () => ({
  temperature: (Math.random() * 15 + 20).toFixed(1),
  humidity: (Math.random() * 30 + 50).toFixed(1),
  soilMoisture: (Math.random() * 30 + 40).toFixed(1),
  lightLevel: (Math.random() * 5000 + 5000).toFixed(0),
  lastUpdated: new Date().toLocaleTimeString()
});

// Routes
app.get('/', (req, res) => res.redirect('/plant'));

app.get('/plant', (req, res) => {
  res.render('plant', {
    devices: devices.map(device => ({
      ...device,
      plants: plants.filter(p => p.deviceId === device.id)
    })),
    helpers
  });
});

app.post('/add-device', async (req, res) => {
  const newDevice = {
    id: Date.now().toString(),
    name: req.body.name,
    location: req.body.location || 'Field 1',
    virtualPins: helpers.createVirtualPins(),
    sensorData: {
      temperature: 0,
      humidity: 0,
      soilMoisture: 0,
      lightLevel: 0
    },
    lastSynced: new Date().toISOString()
  };

  // Initialize Blynk pins
  try {
    await Promise.all([
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.soilTemp, 0),
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.soilMoisture, 0),
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.airTemp, 0),
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.airHumidity, 0),
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.light, 0),
      helpers.updateBlynk(newDevice.id, newDevice.virtualPins.aiComms, 'INIT')
    ]);
  } catch (error) {
    console.error('Blynk initialization failed:', error);
  }

  devices.push(newDevice);
  res.redirect('/plant');
});

app.post('/add-plant', (req, res) => {
  const newPlant = {
    id: Date.now().toString(),
    deviceId: req.body.deviceId,
    type: req.body.plantType,
    stats: getMockSensorData(),
    addedAt: new Date().toLocaleString(),
    recommendations: generateRecommendations(req.body.plantType)
  };

  plants.push(newPlant);
  res.redirect('/plant');
});

// AI Recommendation Engine
function generateRecommendations(plantType) {
  const recommendations = {
    Cassava: ['Maintain pH 6.0-6.8', 'Water 1-2 inches weekly'],
    Melon: ['Keep soil moist', 'Use nitrogen-rich fertilizer'],
    Maze: ['Full sunlight required', 'Maintain 21-29°C'],
    Palm: ['Prune regularly', 'Avoid overwatering'],
    Yam: ['Well-drained soil', 'Maintain 6.0-6.5 pH']
  };
  return recommendations[plantType] || ['No specific recommendations'];
}

app.listen(PORT, () => {
  console.log(`Smart Farm Dashboard running on http://localhost:${PORT}`);
});



...............................................................................
const express = require('express');
const path = require('path');
const fetch = require('node-fetch');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Mock databases
let devices = [];
let plants = [];

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Blynk Configuration
const BLYNK_TOKEN = 'oeTMuwQklxSeHlJqH7fDifJlMjCdo8K_';
const BLYNK_URL = 'https://ny3.blynk.cloud/external/api/get';

// Device pin mapping
const DEVICE_PINS = {
  temperature: 'v2',
  humidity: 'v3',
  soilMoisture: 'v1',
  light: 'v5'
};

// Helper functions
const helpers = {
  getStatus: (value, min, max) => {
    if (value === 'Offline') return 'offline';
    const num = parseFloat(value);
    if (isNaN(num)) return 'unknown';
    if (num < min || num > max) return 'critical';
    if (num < min + 0.2*(max-min) || num > max - 0.2*(max-min)) return 'warning';
    return 'normal';
  },
  generateRecommendations: (plantType) => {
    const recommendations = {
      Cassava: ['Maintain pH 6.0-6.8', 'Water 1-2 inches weekly'],
      Melon: ['Keep soil moist', 'Use nitrogen-rich fertilizer'],
      Maze: ['Full sunlight required', 'Maintain 21-29°C'],
      Palm: ['Prune regularly', 'Avoid overwatering'],
      Yam: ['Well-drained soil', 'Maintain 6.0-6.5 pH']
    };
    return recommendations[plantType] || ['No specific recommendations'];
  }
};

// Get Blynk data with error handling
async function getBlynkData(pin) {
  try {
    const response = await fetch(`${BLYNK_URL}?token=${BLYNK_TOKEN}&${pin}`);
    const data = await response.json();
    console.log(data);
    
    // Handle Blynk error response
    if (data.error && data.error.message.includes("doesn't have any value")) {
      return 'Offline';
    }
    return data.toString();
  } catch (error) {
    console.error(`Error fetching Blynk data for pin ${pin}:`, error);
    return 'Offline';
  }
}

// Get sensor data for a device
async function getDeviceSensorData(deviceId) {
  const [temperature, humidity, soilMoisture, light] = await Promise.all([
    getBlynkData(DEVICE_PINS.temperature),
    getBlynkData(DEVICE_PINS.humidity),
    getBlynkData(DEVICE_PINS.soilMoisture),
    getBlynkData(DEVICE_PINS.light)
  ]);

  return {
    temperature,
    humidity,
    soilMoisture,
    lightLevel: light,
    lastUpdated: new Date().toLocaleTimeString()
  };
}

// Routes
app.get('/', (req, res) => res.redirect('/plant'));

app.get('/plant', async (req, res) => {
  // Update all plants with current sensor data
  for (const plant of plants) {
    plant.stats = await getDeviceSensorData(plant.deviceId);
  }

  res.render('plant', { 
    devices: devices.map(d => ({
      ...d,
      plants: plants.filter(p => p.deviceId === d.id)
    })), 
    helpers 
  });
});

app.post('/add-device', (req, res) => {
  devices.push({
    id: Date.now().toString(),
    name: req.body.name,
    location: req.body.location || 'Unspecified Location'
  });
  res.redirect('/plant');
});

app.post('/add-plant', async (req, res) => {
  if (!devices.some(d => d.id === req.body.deviceId)) {
    return res.redirect('/plant');
  }

  plants.push({
    id: Date.now().toString(),
    deviceId: req.body.deviceId,
    type: req.body.plantType,
    stats: await getDeviceSensorData(req.body.deviceId),
    recommendations: helpers.generateRecommendations(req.body.plantType)
  });

  res.redirect('/plant');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
///////////////////////////////////////////////////////////////////////////////
const express = require('express');
const path = require('path');
const fetch = require('node-fetch');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Mock databases
let devices = [];
let plants = [];

// Middleware
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Blynk Configuration
const BLYNK_TOKEN = 'oeTMuwQklxSeHlJqH7fDifJlMjCdo8K_';
const BLYNK_URL = 'https://ny3.blynk.cloud/external/api/get';


// Device pin mapping
const DEVICE_PINS = {
  temperature: 'v2',
  humidity: 'v3',
  soilMoisture: 'v1',
  light: 'v5'
};

// Helper functions
const helpers = {
  getStatus: (value, min, max) => {
    if (value === 'Offline') return 'offline';
    const num = parseFloat(value);
    if (isNaN(num)) return 'unknown';
    if (num < min || num > max) return 'critical';
    if (num < min + 0.2*(max-min) || num > max - 0.2*(max-min)) return 'warning';
    return 'normal';
  },
  generateRecommendations: (plantType) => {
    const recommendations = {
      Cassava: ['Maintain pH 6.0-6.8', 'Water 1-2 inches weekly'],
      Melon: ['Keep soil moist', 'Use nitrogen-rich fertilizer'],
      Maze: ['Full sunlight required', 'Maintain 21-29°C'],
      Palm: ['Prune regularly', 'Avoid overwatering'],
      Yam: ['Well-drained soil', 'Maintain 6.0-6.5 pH']
    };
    return recommendations[plantType] || ['No specific recommendations'];
  }
};

// Get Blynk data with improved error handling
async function getBlynkData(pin) {
  try {
    const response = await fetch(`${BLYNK_URL}?token=${BLYNK_TOKEN}&${pin}`);
    
    // Handle HTTP errors
    if (!response.ok) {
      console.error(`Blynk error: ${response.status} ${response.statusText}`);
      return 'Offline';
    }
    
    // Try to parse as JSON first
    try {
      const data = await response.json();
      
      // Handle Blynk error response
      if (data.error && data.error.message.includes("doesn't have any value")) {
        return 'Offline';
      }
      return data.toString();
    } catch (e) {
      // If JSON parsing fails, treat as plain text
      return await response.text();
    }
  } catch (error) {
    console.error(`Network error: ${error.message}`);
    return 'Offline';
  }
}

// Get sensor data for a device
async function getDeviceSensorData(deviceId) {
  const [temperature, humidity, soilMoisture, light] = await Promise.all([
    getBlynkData(DEVICE_PINS.temperature),
    getBlynkData(DEVICE_PINS.humidity),
    getBlynkData(DEVICE_PINS.soilMoisture),
    getBlynkData(DEVICE_PINS.light)
  ]);

  return {
    temperature,
    humidity,
    soilMoisture,
    lightLevel: light,
    lastUpdated: new Date().toLocaleTimeString()
  };
}

// Routes
app.get('/', (req, res) => res.redirect('/plant'));

app.get('/plant', async (req, res) => {
  console.log("Fetching Blynk data for all plants...");
  
  // Update all plants with current sensor data
  for (const plant of plants) {
    try {
      const newStats = await getDeviceSensorData(plant.deviceId);
      plant.stats = newStats;
      
      // Log the updated plant data
      console.log(`Updated plant ${plant.id} (${plant.type}) with device ${plant.deviceId}:`, newStats);
    } catch (error) {
      console.error(`Error updating plant ${plant.id}: ${error.message}`);
    }
  }

  res.render('plant', { 
    devices: devices.map(d => ({
      ...d,
      plants: plants.filter(p => p.deviceId === d.id)
    })), 
    helpers 
  });
});

app.post('/add-device', (req, res) => {
  const newDevice = {
    id: Date.now().toString(),
    name: req.body.name,
    location: req.body.location || 'Unspecified Location'
  };
  devices.push(newDevice);
  console.log(`Added new device: ${newDevice.name} (${newDevice.id})`);
  res.redirect('/plant');
});

app.post('/add-plant', async (req, res) => {
  const device = devices.find(d => d.id === req.body.deviceId);
  if (!device) {
    console.error(`Device not found: ${req.body.deviceId}`);
    return res.redirect('/plant');
  }

  const newPlant = {
    id: Date.now().toString(),
    deviceId: req.body.deviceId,
    type: req.body.plantType,
    stats: await getDeviceSensorData(req.body.deviceId),
    recommendations: helpers.generateRecommendations(req.body.plantType)
  };

  plants.push(newPlant);
  console.log(`Added new plant: ${newPlant.type} on device ${device.name}`);
  res.redirect('/plant');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});