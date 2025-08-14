#!/bin/sh

# Wait for database to be ready
echo "Waiting for database to be ready..."
while ! node -e "
  const { Pool } = require('pg');
  const pool = new Pool({ connectionString: process.env.DATABASE_URL });
  pool.query('SELECT 1', (err) => {
    if (err) {
      console.error('Database not ready:', err.message);
      process.exit(1);
    }
    console.log('Database is ready!');
    pool.end();
    process.exit(0);
  });
" 2>/dev/null; do
  sleep 2
done

# Seed the database
echo "Seeding database..."
cd /app/backend
npx tsx src/db/seed.ts

# Start the application
echo "Starting application..."
cd /app/backend
exec node dist/index.js
