#!/bin/bash

# Docker Environment Initialization Script
# This script installs Docker and configures the environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
    exit 1
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    log_warning "Docker is already installed."
    docker --version
    read -p "Do you want to reinstall Docker? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Docker installation skipped."
        exit 0
    fi
fi

log_info "Starting Docker installation..."

# Update package index
log_info "Updating package index..."
if ! sudo apt-get update; then
    log_error "Failed to update package index. Please check your internet connection and try again."
    exit 1
fi

# Install required packages
log_info "Installing required packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https

# Download Docker installation script
log_info "Downloading Docker installation script..."
if ! curl -fsSL https://get.docker.com -o get-docker.sh; then
    log_error "Failed to download Docker installation script. Please check your internet connection."
    exit 1
fi

# Make script executable
chmod +x get-docker.sh

# Execute Docker installation script
log_info "Installing Docker..."
if ! sudo sh ./get-docker.sh; then
    log_error "Docker installation failed. Please check the output above for errors."
    rm -f get-docker.sh
    exit 1
fi

# Clean up installation script
rm -f get-docker.sh

# Add docker group if it doesn't exist
log_info "Configuring Docker group..."
if ! getent group docker >/dev/null; then
    sudo groupadd docker
    log_success "Docker group created."
else
    log_info "Docker group already exists."
fi

# Add current user to docker group
log_info "Adding user '$USER' to docker group..."
if ! sudo usermod -aG docker "$USER"; then
    log_error "Failed to add user to docker group."
    exit 1
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_info "Installing Docker Compose..."
    sudo apt-get install -y docker-compose-plugin
fi

# Verify installation
log_info "Verifying Docker installation..."
if docker --version; then
    log_success "Docker installed successfully!"
    docker --version
else
    log_error "Docker installation verification failed."
    exit 1
fi

# Check if Docker Compose is available
if docker compose version &> /dev/null; then
    log_success "Docker Compose is available!"
    docker compose version
elif command -v docker-compose &> /dev/null; then
    log_success "Docker Compose (legacy) is available!"
    docker-compose --version
else
    log_warning "Docker Compose is not available. You may need to install it separately."
fi

# Final instructions
echo
log_success "Docker installation completed successfully!"
echo
log_warning "IMPORTANT: You need to log out and log back in (or restart your terminal) for group changes to take effect."
echo
log_info "After logging back in, you can test Docker with:"
echo "  docker run hello-world"
echo
log_info "To start the curse project services, run:"
echo "  ./start_all.sh"
echo
log_info "For more information, see the README.md file."