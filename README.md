# Curse Project - Docker Compose Setup

This project uses separate Docker Compose files for each service. The shell scripts have been updated to use Docker Compose instead of individual `docker run` commands.

## Services

Each service has its own Docker Compose file:

- **Portainer** - Docker management UI (ports 8000, 9000, 9443)
  - File: `docker-compose.portainer.yml`
- **Bark Server** - iOS push notification service (port 8087)
  - File: `docker-compose.bark.yml`
- **LibreChat** - AI Chat Interface (port 3080)
  - Repository: Cloned from https://github.com/danny-avila/LibreChat.git
  - Configuration: `LibreChat/.env` (created from `.env.example` on first run)

## Quick Start

### Start All Services
```bash
./start_all.sh
```

### Start Individual Services
```bash
./start_potainer.sh     # Start Portainer only
./start_bark.sh         # Start Bark Server only
./start_librechat.sh    # Start LibreChat only
```

### Stop All Services
```bash
./stop_all.sh
```

### Additional Scripts
```bash
./init_docker_env.sh        # Install and configure Docker
./update_fastest_mirror.sh  # Find and update to fastest Ubuntu mirror
```

## Docker Compose Commands

### Portainer Commands
```bash
# Start Portainer
docker compose -f docker-compose.portainer.yml up -d

# Stop Portainer
docker compose -f docker-compose.portainer.yml down

# View Portainer logs
docker compose -f docker-compose.portainer.yml logs

# Restart Portainer
docker compose -f docker-compose.portainer.yml restart
```

### Bark Commands
```bash
# Start Bark
docker compose -f docker-compose.bark.yml up -d

# Stop Bark
docker compose -f docker-compose.bark.yml down

# View Bark logs
docker compose -f docker-compose.bark.yml logs

# Restart Bark
docker compose -f docker-compose.bark.yml restart
```

### LibreChat Commands
```bash
# Start LibreChat (automatically clones repo and sets up .env)
./start_librechat.sh

# Or use Docker Compose directly from LibreChat directory
cd LibreChat
docker compose up -d
cd ..

# Stop LibreChat
cd LibreChat
docker compose down
cd ..

# View LibreChat logs
cd LibreChat
docker compose logs
cd ..

# Restart LibreChat
cd LibreChat
docker compose restart
cd ..
```

**Note:** The `start_librechat.sh` script follows the official LibreChat installation:
1. Clones the repository if not present: `git clone https://github.com/danny-avila/LibreChat.git`
2. Creates `.env` from `.env.example`: `cp .env.example .env`
3. Starts LibreChat: `docker compose up -d`

After first run, edit `LibreChat/.env` to configure your API keys and settings.

## Access URLs

- **Portainer**: http://localhost:8000 or http://localhost:9000
- **Bark Server**: http://localhost:8087
- **LibreChat**: http://localhost:3080

## Configuration Files

- `docker-compose.portainer.yml` - Portainer Docker Compose configuration
- `docker-compose.bark.yml` - Bark Docker Compose configuration
- `LibreChat/` - LibreChat repository (cloned automatically by start script)
- `LibreChat/.env` - LibreChat environment configuration (edit this file for API keys)
- `init_docker_env.sh` - Docker installation and environment setup script
- `update_fastest_mirror.sh` - Ubuntu mirror finder and system updater
- `start_all.sh` - Start all services script
- `start_librechat.sh` - Clone and start LibreChat
- `stop_all.sh` - Stop all services script

## Migration from Shell Scripts

The original shell scripts have been updated to use Docker Compose:
- `start_potainer.sh` - Now uses `docker compose -f docker-compose.portainer.yml up -d`
- `start_bark.sh` - Now uses `docker compose -f docker-compose.bark.yml up -d`
- `start_librechat.sh` - Follows official LibreChat setup (clone → create .env → start)
- `init_docker_env.sh` - Improved Docker installation script with better error handling
- `update_fastest_mirror.sh` - Enhanced Ubuntu mirror finder that automatically updates system sources

## Volumes and Networks

### Portainer
- `portainer_data` - Portainer configuration and data
- `portainer-network` - Portainer network

### Bark
- `bark-network` - Bark network

### LibreChat
- `LibreChat/` - Cloned repository (managed by Docker Compose within)
- All volumes and networks are managed within the LibreChat directory

## Troubleshooting

### View Service Logs
```bash
# Portainer logs
docker compose -f docker-compose.portainer.yml logs

# Bark logs
docker compose -f docker-compose.bark.yml logs

# LibreChat logs
cd LibreChat && docker compose logs && cd ..
```

### Check Service Status
```bash
# Check all containers
docker ps

# Check specific service
docker compose -f docker-compose.portainer.yml ps
docker compose -f docker-compose.bark.yml ps
cd LibreChat && docker compose ps && cd ..
```

### Restart a Service
```bash
# Restart Portainer
docker compose -f docker-compose.portainer.yml restart

# Restart Bark
docker compose -f docker-compose.bark.yml restart

# Restart LibreChat
cd LibreChat && docker compose restart && cd ..
```

### Rebuild and Start
```bash
# Rebuild and start Portainer
docker compose -f docker-compose.portainer.yml up -d --build

# Rebuild and start Bark
docker compose -f docker-compose.bark.yml up -d --build

# Rebuild and start LibreChat
cd LibreChat && docker compose up -d --build && cd ..
```
