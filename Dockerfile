# Multi-stage build for fast builds
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY backend/package*.json ./backend/
COPY frontend/package*.json ./frontend/

# Install dependencies
RUN npm install --only=production && npm cache clean --force

# Build the frontend
FROM base AS frontend-builder
WORKDIR /app

# Copy frontend files
COPY frontend/package*.json ./frontend/
COPY frontend/ ./frontend/

# Install frontend dependencies and build
WORKDIR /app/frontend
RUN npm install
RUN npm run build

# Build the backend
FROM base AS backend-builder
WORKDIR /app

# Copy backend files
COPY backend/package*.json ./backend/
COPY backend/ ./backend/

# Install backend dependencies and build
WORKDIR /app/backend
RUN npm install
RUN npm run build

# Production stage
FROM base AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy built applications
COPY --from=frontend-builder --chown=nextjs:nodejs /app/frontend/dist ./frontend/dist
COPY --from=backend-builder --chown=nextjs:nodejs /app/backend/dist ./backend/dist
COPY --from=backend-builder --chown=nextjs:nodejs /app/backend/package*.json ./backend/

# Copy seed script
COPY --from=backend-builder --chown=nextjs:nodejs /app/backend/src/db/seed.ts ./backend/src/db/seed.ts

# Install only production dependencies for backend
WORKDIR /app/backend
RUN npm install --only=production && npm cache clean --force

# Copy startup script
COPY --chown=nextjs:nodejs docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Switch to non-root user
USER nextjs

# Expose port
EXPOSE 3001

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the application
ENTRYPOINT ["/app/docker-entrypoint.sh"]
