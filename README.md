# Compliance Dashboard - Docker Deployment

This repository contains a dockerized compliance dashboard with separate frontend and backend applications.

## Architecture

- **Backend**: Node.js/Express API running on port 4000
- **Frontend**: React application served via nginx on port 3000
- **Docker Compose**: Orchestrates both containers with health checks and networking

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Ports 3000 and 4000 available on your system

### Run the Application

1. **Start both services:**

   ```bash
   docker-compose up -d
   ```

2. **View logs:**

   ```bash
   docker-compose logs -f
   ```

3. **Access the applications:**
   - Frontend: <http://localhost:3002>
   - Backend API: <http://localhost:4000>

4. **Stop the services:**

   ```bash
   docker-compose down
   ```

## Individual Container Commands

### Backend

```bash
# Build backend image
docker build -t compliance-backend ./backend

# Run backend container
docker run -d -p 4000:4000 --name backend compliance-backend
```

### Frontend

```bash
# Build frontend image
docker build -t compliance-frontend ./frontend

# Run frontend container
docker run -d -p 3000:3000 --name frontend compliance-frontend
```

## Development

### Build Images Separately

```bash
# Backend
cd backend && docker build -t compliance-backend .

# Frontend
cd frontend && docker build -t compliance-frontend .
```

### Rebuild and Restart

```bash
docker-compose up --build -d
```

## Health Checks

Both services include health checks:

- Backend: Checks `/health` endpoint
- Frontend: Checks nginx availability

View health status:

```bash
docker-compose ps
```

## Troubleshooting

### View container logs

```bash
docker-compose logs backend
docker-compose logs frontend
```

### Rebuild from scratch

```bash
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Check container status

```bash
docker ps
```
