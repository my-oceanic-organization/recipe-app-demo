#!/bin/sh

echo "🚀 Starting Recipe App..."

echo "🔄 Waiting for database..."
timeout 60 sh -c 'until node -e "new (require(\"pg\").Pool)({connectionString: process.env.DATABASE_URL}).query(\"SELECT NOW()\").then(() => process.exit(0)).catch(() => process.exit(1))"; do sleep 2; done'

echo "✅ Database ready!"

echo "🌱 Seeding database..."
npx tsx src/db/seed.ts

echo "✅ Database seeded!"

echo "🚀 Starting server on port 3000..."
node dist/index.js
