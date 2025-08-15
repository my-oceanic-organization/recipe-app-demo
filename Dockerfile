# Multi-stage build for Recipe App with optimized build time
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS base

# Build the frontend with optimized caching
FROM base AS frontend-builder
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.npm \
    npm install --legacy-peer-deps --prefer-offline --no-audit

# Copy source and build
COPY frontend/ ./frontend/
WORKDIR /app/frontend
RUN npm run build

# Build the backend with optimized caching
FROM base AS backend-builder
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies with cache mount for faster rebuilds
RUN --mount=type=cache,target=/root/.npm \
    npm install --legacy-peer-deps --prefer-offline --no-audit

# Copy source files
COPY backend/ ./backend/

# Production stage - minimal and optimized
FROM node:18-alpine AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 demouser

# Copy only necessary files from builders
COPY --from=frontend-builder --chown=demouser:nodejs /app/frontend/dist ./frontend/dist
COPY --from=backend-builder --chown=demouser:nodejs /app/backend/src ./backend/src
COPY --from=backend-builder --chown=demouser:nodejs /app/package*.json ./

# Install only production dependencies with cache mount
RUN --mount=type=cache,target=/root/.npm \
    npm ci --only=production --legacy-peer-deps --prefer-offline --no-audit && \
    npm cache clean --force

# Switch to non-root user
USER demouser

# Expose port
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

# Start the application
CMD echo "🚀 Starting Recipe App..." && \
    echo "🌱 Seeding database..." && \
    node backend/src/db/seed.js && \
    echo "✅ Database seeded!" && \
    echo "🚀 Starting server on port 3000..." && \
    node backend/src/index.js
