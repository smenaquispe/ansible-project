const express = require("express");
const { Pool } = require("pg");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Crear un router para las rutas de API
const apiRouter = express.Router();

// Array para almacenar queries para debugging (como telescope)
let queryLog = [];

const pool = new Pool({
  host: process.env.DB_HOST || "db",
  user: process.env.DB_USER || "admin",
  password: process.env.DB_PASSWORD || "admin",
  database: process.env.DB_NAME || "todos",
});

// Middleware para logging de queries
const logQuery = (query, params) => {
  const logEntry = {
    id: Date.now(),
    timestamp: new Date().toISOString(),
    query: query,
    params: params || [],
    executionTime: Date.now()
  };
  queryLog.unshift(logEntry);
  // Mantener solo las últimas 100 queries
  if (queryLog.length > 100) {
    queryLog = queryLog.slice(0, 100);
  }
  return logEntry;
};

// Helper para ejecutar queries con logging
const executeQuery = async (query, params = []) => {
  const logEntry = logQuery(query, params);
  const startTime = Date.now();
  try {
    const result = await pool.query(query, params);
    logEntry.executionTime = Date.now() - startTime;
    logEntry.status = 'success';
    logEntry.rowCount = result.rowCount;
    return result;
  } catch (error) {
    logEntry.executionTime = Date.now() - startTime;
    logEntry.status = 'error';
    logEntry.error = error.message;
    throw error;
  }
};

// Rutas para TODOs - ahora en el router
apiRouter.get("/todos", async (req, res) => {
  try {
    const result = await executeQuery("SELECT * FROM todos ORDER BY id ASC");
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

apiRouter.post("/todos", async (req, res) => {
  try {
    const { task } = req.body;
    if (!task || task.trim() === '') {
      return res.status(400).json({ error: 'Task is required' });
    }
    const result = await executeQuery("INSERT INTO todos (task) VALUES ($1) RETURNING *", [task.trim()]);
    res.status(201).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

apiRouter.put("/todos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { task } = req.body;
    if (!task || task.trim() === '') {
      return res.status(400).json({ error: 'Task is required' });
    }
    const result = await executeQuery("UPDATE todos SET task = $1 WHERE id = $2 RETURNING *", [task.trim(), id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

apiRouter.delete("/todos/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await executeQuery("DELETE FROM todos WHERE id = $1 RETURNING *", [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.json({ message: 'Todo deleted successfully', todo: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Ruta para toggle completed status
apiRouter.patch("/todos/:id/toggle", async (req, res) => {
  try {
    const { id } = req.params;
    const result = await executeQuery("UPDATE todos SET completed = NOT COALESCE(completed, false) WHERE id = $1 RETURNING *", [id]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Todo not found' });
    }
    res.json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Rutas de debugging/monitoring (como Telescope)
apiRouter.get("/debug/queries", (req, res) => {
  res.json({
    total: queryLog.length,
    queries: queryLog
  });
});

apiRouter.delete("/debug/queries", (req, res) => {
  queryLog = [];
  res.json({ message: 'Query log cleared' });
});

apiRouter.get("/debug/stats", async (req, res) => {
  try {
    const totalTodos = await executeQuery("SELECT COUNT(*) as count FROM todos");
    const completedTodos = await executeQuery("SELECT COUNT(*) as count FROM todos WHERE completed = true");
    const pendingTodos = await executeQuery("SELECT COUNT(*) as count FROM todos WHERE completed = false OR completed IS NULL");
    
    res.json({
      database: {
        totalTodos: parseInt(totalTodos.rows[0].count),
        completedTodos: parseInt(completedTodos.rows[0].count),
        pendingTodos: parseInt(pendingTodos.rows[0].count)
      },
      queries: {
        totalExecuted: queryLog.length,
        successfulQueries: queryLog.filter(q => q.status === 'success').length,
        failedQueries: queryLog.filter(q => q.status === 'error').length,
        averageExecutionTime: queryLog.length > 0 ? 
          Math.round(queryLog.reduce((sum, q) => sum + q.executionTime, 0) / queryLog.length) : 0
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
apiRouter.get("/health", async (req, res) => {
  try {
    await executeQuery("SELECT 1");
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ status: 'unhealthy', error: error.message });
  }
});

// Montar el router en /api (el Ingress envía /api/*)
app.use('/api', apiRouter);

app.listen(5000, () => {
  console.log("Backend corriendo en puerto 5000");
  console.log("Rutas disponibles:");
  console.log("  - GET /api/todos - Ver todas las tareas");
  console.log("  - POST /api/todos - Crear nueva tarea");
  console.log("  - PUT /api/todos/:id - Actualizar tarea");
  console.log("  - DELETE /api/todos/:id - Eliminar tarea");
  console.log("  - PATCH /api/todos/:id/toggle - Toggle completado");
  console.log("  - GET /api/health - Health check");
  console.log("  - GET /api/debug/queries - Ver queries ejecutadas");
  console.log("  - GET /api/debug/stats - Ver estadísticas");
});
