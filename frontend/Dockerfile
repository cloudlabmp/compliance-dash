# Multi-stage build for React frontend
FROM node:20-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build the React application
RUN npm run build

# Production stage with nginx
FROM nginx:alpine AS production

# Copy built React app to nginx serve directory
COPY --from=builder /app/build /usr/share/nginx/html

# Use default nginx configuration

# Create non-root user
RUN addgroup -g 1001 -S nginx-user && \
    adduser -S nginx-user -u 1001

# Expose port 3000
EXPOSE 3000

# Configure nginx to run on port 3000
RUN sed -i 's/listen       80;/listen       3000;/' /etc/nginx/conf.d/default.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]