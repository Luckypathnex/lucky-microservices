const express = require("express");
const { Pool } = require("pg");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3000;
const SERVICE_NAME = "order-service";

// Database configuration
const pool = new Pool({
  host: process.env.DB_HOST || "localhost",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "orders_db",
  user: process.env.DB_USER || "postgres",
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Database connection test
pool.on("error", (err) => {
  console.error("Unexpected database error:", err.message);
});

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// Health check endpoints for K8s
app.get("/health", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).json({ 
      status: "healthy", 
      service: SERVICE_NAME,
      database: "connected",
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    res.status(503).json({ 
      status: "unhealthy", 
      service: SERVICE_NAME,
      database: "disconnected",
      error: error.message,
      timestamp: new Date().toISOString() 
    });
  }
});

app.get("/ready", async (req, res) => {
  try {
    await pool.query("SELECT 1");
    res.status(200).json({ 
      status: "ready", 
      service: SERVICE_NAME,
      timestamp: new Date().toISOString() 
    });
  } catch (error) {
    res.status(503).json({ 
      status: "not ready", 
      error: error.message 
    });
  }
});

// Main endpoint
app.get("/", (req, res) => {
  res.json({ 
    message: "Order Service Running", 
    service: SERVICE_NAME,
    version: process.env.VERSION || "1.0.0",
    environment: process.env.NODE_ENV || "development"
  });
});

// API Routes
app.get("/api/orders", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM orders ORDER BY created_at DESC LIMIT 100");
    res.json({ 
      orders: result.rows,
      count: result.rowCount
    });
  } catch (error) {
    console.error("Database error:", error.message);
    res.status(500).json({ 
      error: "Database error",
      message: error.message 
    });
  }
});

app.get("/api/orders/:id", async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM orders WHERE id = $1", [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: "Order not found" });
    }
    res.json({ order: result.rows[0] });
  } catch (error) {
    console.error("Database error:", error.message);
    res.status(500).json({ error: error.message });
  }
});

app.post("/api/orders", async (req, res) => {
  const { customer_id, total_amount, status } = req.body;
  try {
    const result = await pool.query(
      "INSERT INTO orders (customer_id, total_amount, status) VALUES ($1, $2, $3) RETURNING *",
      [customer_id, total_amount, status || "pending"]
    );
    res.status(201).json({ order: result.rows[0] });
  } catch (error) {
    console.error("Database error:", error.message);
    res.status(500).json({ error: error.message });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Not Found" });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(`Error: ${err.message}`);
  res.status(500).json({ 
    error: "Internal Server Error",
    message: process.env.NODE_ENV === "development" ? err.message : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`${SERVICE_NAME} running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Database: ${process.env.DB_HOST || "localhost"}:${process.env.DB_PORT || 5432}`);
});

module.exports = app;