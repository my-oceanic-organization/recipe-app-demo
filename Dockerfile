# Multi-stage build for Recipe App with optimized build time
# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS base

# Install all dependencies and build
FROM base AS builder
WORKDIR /app

# Copy package files first for better layer caching
COPY package*.json ./

# Install all dependencies
RUN npm ci

# Copy source files
COPY . .

# Build the frontend
WORKDIR /app/frontend
RUN npm run build

# Production stage - minimal and optimized
FROM node:18-alpine AS runner
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 demouser

# Copy only necessary files from builder
COPY --from=builder --chown=demouser:nodejs /app/frontend/dist ./frontend/dist
COPY --from=builder --chown=demouser:nodejs /app/backend/src ./backend/src
COPY --from=builder --chown=demouser:nodejs /app/package*.json ./

# Copy only production dependencies
COPY --from=builder --chown=demouser:nodejs /app/node_modules ./node_modules

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
