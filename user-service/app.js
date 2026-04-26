const express = require("express");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcrypt");
require("dotenv").config();

const app = express();
const PORT = process.env.PORT || 3001;
const SERVICE_NAME = "user-service";
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key-change-in-production";

// In-memory user store (replace with database in production)
const users = new Map();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});

// JWT Authentication middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  
  if (!token) {
    return res.status(401).json({ error: "Access token required" });
  }
  
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: "Invalid or expired token" });
    }
    req.user = user;
    next();
  });
};

// Health check endpoints for K8s
app.get("/health", (req, res) => {
  res.status(200).json({ 
    status: "healthy", 
    service: SERVICE_NAME,
    timestamp: new Date().toISOString() 
  });
});

app.get("/ready", (req, res) => {
  res.status(200).json({ 
    status: "ready", 
    service: SERVICE_NAME,
    timestamp: new Date().toISOString() 
  });
});

// Main endpoint
app.get("/", (req, res) => {
  res.json({ 
    message: "User Service Running", 
    service: SERVICE_NAME,
    version: process.env.VERSION || "1.0.0",
    environment: process.env.NODE_ENV || "development"
  });
});

// Auth Routes
app.post("/api/auth/register", async (req, res) => {
  const { username, email, password } = req.body;
  
  if (!username || !email || !password) {
    return res.status(400).json({ error: "Missing required fields" });
  }
  
  if (users.has(email)) {
    return res.status(409).json({ error: "User already exists" });
  }
  
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const user = {
      id: Date.now().toString(),
      username,
      email,
      password: hashedPassword,
      createdAt: new Date().toISOString()
    };
    
    users.set(email, user);
    res.status(201).json({ 
      message: "User created successfully",
      user: { id: user.id, username, email }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post("/api/auth/login", async (req, res) => {
  const { email, password } = req.body;
  
  if (!email || !password) {
    return res.status(400).json({ error: "Email and password required" });
  }
  
  const user = users.get(email);
  if (!user) {
    return res.status(401).json({ error: "Invalid credentials" });
  }
  
  try {
    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: "Invalid credentials" });
    }
    
    const accessToken = jwt.sign(
      { id: user.id, username: user.username, email: user.email },
      JWT_SECRET,
      { expiresIn: "24h" }
    );
    
    res.json({ 
      accessToken,
      user: { id: user.id, username: user.username, email: user.email }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Protected Routes
app.get("/api/users", authenticateToken, (req, res) => {
  const userList = Array.from(users.values()).map(u => ({
    id: u.id,
    username: u.username,
    email: u.email,
    createdAt: u.createdAt
  }));
  res.json({ users: userList });
});

app.get("/api/users/:id", authenticateToken, (req, res) => {
  const user = Array.from(users.values()).find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ error: "User not found" });
  }
  res.json({ 
    user: { 
      id: user.id, 
      username: user.username, 
      email: user.email,
      createdAt: user.createdAt 
    }
  });
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
});

module.exports = app;