const express = require("express");
const path = require("path");
const https = require("https");
const http = require("http");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize databases
let devices = [];
let plants = [];

// Middleware
app.use(express.static(path.join(__dirname, "public")));
app.use(express.urlencoded({ extended: true }));
app.set("view engine", "ejs");
app.set("views", path.join(__dirname, "views"));

// Blynk Configuration
const BLYNK_TOKEN = "oeTMuwQklxSeHlJqH7fDifJlMjCdo8K_";
const BLYNK_HOST = "ny3.blynk.cloud";

// Device pin ranges configuration
const DEVICE_PIN_RANGES = [
  { start: 0, end: 5 }, // Device 1
  { start: 6, end: 11 }, // Device 2
  { start: 12, end: 17 }, // Device 3
  { start: 18, end: 23 }, // Device 4
  { start: 24, end: 29 }, // Device 5
];

// Helper functions
const helpers = {
  getStatus: (value, min, max) => {
    if (value === "Offline") return "offline";
    const num = parseFloat(value);
    if (isNaN(num)) return "unknown";
    if (num < min || num > max) return "critical";
    if (num < min + 0.2 * (max - min) || num > max - 0.2 * (max - min))
      return "warning";
    return "normal";
  },
  generateRecommendations: (plantType) => {
    const recommendations = {
      Cassava: ["Maintain pH 6.0-6.8", "Water 1-2 inches weekly"],
      Melon: ["Keep soil moist", "Use nitrogen-rich fertilizer"],
      Maize: ["Full sunlight required", "Maintain 21-29°C"],
      Palm: ["Prune regularly", "Avoid overwatering"],
      Yam: ["Well-drained soil", "Maintain 6.0-6.5 pH"],
      ScentLeaf: ["Keep soil moist", "Avoid direct sunlight"]
    };
    return recommendations[plantType] || ["No specific recommendations"];
  },
};

// Function to make HTTPS request to Blynk
function getBlynkValue(pin) {
  return new Promise((resolve) => {
    const options = {
      hostname: BLYNK_HOST,
      path: `/external/api/get?token=${BLYNK_TOKEN}&${pin}`,
      method: "GET",
      timeout: 5000,
    };

    const req = https.request(options, (res) => {
      let data = "";

      res.on("data", (chunk) => {
        data += chunk;
      });

      res.on("end", () => {
        if (res.statusCode !== 200) {
          console.error(
            `Blynk API error for pin ${pin}: Status ${res.statusCode}`
          );
          resolve("Offline");
          return;
        }

        try {
          const jsonData = JSON.parse(data);
          if (jsonData.error) {
            console.error(
              `Blynk error for pin ${pin}: ${jsonData.error.message}`
            );
            resolve("Offline");
            return;
          }
        } catch (e) {
          // Not JSON, continue with raw data
        }

        resolve(data || "Offline");
      });
    });

    req.on("error", (error) => {
      console.error(`Request failed for pin ${pin}: ${error.message}`);
      resolve("Offline");
    });

    req.on("timeout", () => {
      req.destroy();
      console.error(`Request timeout for pin ${pin}`);
      resolve("Offline");
    });

    req.end();
  });
}

// Get sensor data for a specific device
async function getDeviceSensorData(deviceIndex) {
  const device = devices[deviceIndex];
  if (!device || !device.pinRange) {
    return {
      soilTemp: "Offline",
      soilMoisture: "Offline",
      temperature: "Offline",
      humidity: "Offline",
      lightLevel: "Offline",
      lastUpdated: new Date().toLocaleTimeString(),
    };
  }

  const [soilTemp, soilMoisture, airTemp, airHumidity, light] =
    await Promise.all([
      getBlynkValue(`v${device.pinRange.start}`),
      getBlynkValue(`v${device.pinRange.start + 1}`),
      getBlynkValue(`v${device.pinRange.start + 2}`),
      getBlynkValue(`v${device.pinRange.start + 3}`),
      getBlynkValue(`v${device.pinRange.start + 5}`),
    ]);

  return {
    soilTemp,
    soilMoisture,
    temperature: airTemp,
    humidity: airHumidity,
    lightLevel: light,
    lastUpdated: new Date().toLocaleTimeString(),
  };
}

// Routes
app.get("/", (req, res) => res.redirect("/plant"));

app.get("/plant", async (req, res) => {
  try {
    // Update all plants with current sensor data
    const updatedPlants = [];
    for (const plant of plants) {
      const device = devices.find((d) => d.id === plant.deviceId);
      if (device) {
        const updatedPlant = {
          ...plant,
          stats: await getDeviceSensorData(device.index),
        };
        updatedPlants.push(updatedPlant);
      }
    }
    plants = updatedPlants;

    res.render("plant", {
      devices: devices || [],
      plants: plants || [],
      helpers: helpers,
    });
  } catch (error) {
    console.error("Error rendering plant page:", error);
    res.status(500).send("Error loading data");
  }
});

app.post("/add-device", (req, res) => {
  if (devices.length >= 5) {
    return res.status(400).send("Maximum 5 devices allowed");
  }

  const newDevice = {
    id: Date.now().toString(),
    name: req.body.name,
    location: req.body.location || "Field 1",
    index: devices.length,
    pinRange: DEVICE_PIN_RANGES[devices.length],
  };

  devices.push(newDevice);
  res.redirect("/plant");
});

app.post("/add-plant", async (req, res) => {
  const device = devices.find((d) => d.id === req.body.deviceId);
  if (!device) return res.redirect("/plant");

  const newPlant = {
    id: Date.now().toString(),
    deviceId: req.body.deviceId,
    type: req.body.plantType,
    stats: await getDeviceSensorData(device.index),
    recommendations: helpers.generateRecommendations(req.body.plantType),
  };

  plants.push(newPlant);
  res.redirect("/plant");
});

// ---------------- WebSocket Setup ----------------
const server = http.createServer(app);
const WebSocket = require("ws");
const wss = new WebSocket.Server({ server });

wss.on("connection", (ws) => {
  console.log("WebSocket client connected");
  ws.send(JSON.stringify({ type: "connected" }));
});

// Periodically broadcast updated plant stats to connected clients
async function broadcastUpdates() {
  const updatedPlants = [];
  for (const plant of plants) {
    const device = devices.find((d) => d.id === plant.deviceId);
    if (device) {
      const updatedPlant = {
        ...plant,
        stats: await getDeviceSensorData(device.index),
      };
      updatedPlants.push(updatedPlant);
    }
  }
  plants = updatedPlants;

  const payload = JSON.stringify({ type: "update", plants });
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(payload);
    }
  });
}
setInterval(broadcastUpdates, 15000);

// Start HTTP & WebSocket server
server.listen(PORT, () => {
  console.log(`Smart Farm Dashboard running with WebSocket on http://localhost:${PORT}`);
});
