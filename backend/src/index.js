const express = require("express");
const cors = require("cors");
const { Pool } = require("pg");
const { recipeRoutes } = require("./routes/recipes");
const path = require("path");

const app = express();
const port = process.env.PORT || 3000;

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false,
    checkServerIdentity: () => undefined,
    ca: undefined,
    cert: undefined,
    key: undefined,
  },
});

// Middleware
app.use(cors());
app.use(express.json());

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// API routes
app.use("/api/recipes", recipeRoutes(pool));

// Serve static files from the frontend build
app.use(express.static(path.join(__dirname, "../../frontend/dist")));

// Serve the React app for any non-API routes
app.get("*", (req, res) => {
  res.sendFile(path.join(__dirname, "../../frontend/dist/index.html"));
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: "Something went wrong!" });
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

module.exports = { pool };
