#!/bin/bash

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function for logging with colors
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Prompt for node name input
read -p "Enter your node name: " NODE_NAME

# Ask if the user wants to install Docker
read -p "Do you want to install Docker? (y/n): " INSTALL_DOCKER

if [ "$INSTALL_DOCKER" = "y" ] || [ "$INSTALL_DOCKER" = "Y" ]; then
    # Update package list and install required dependencies
    log_info "Updating package list..."
    sudo apt-get update && \
    log_info "Installing required dependencies..." && \
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg || {
        log_error "Failed to install dependencies."
        exit 1
    }

    # Download and add Docker GPG key
    log_info "Downloading and adding Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository to APT sources
    log_info "Adding Docker repository to APT sources..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update package list and install Docker
    log_info "Updating package list..."
    sudo apt-get update && \
    log_info "Installing Docker..." && \
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io || {
        log_error "Failed to install Docker."
        exit 1
    }
else
    log_warn "Skipping Docker installation."
fi

# Pull Docker image for analoglabs/timechain
log_info "Pulling Docker image for analoglabs/timechain..."
sudo docker pull analoglabs/timechain || {
    log_error "Failed to pull Docker image."
    exit 1
}

# Run Docker container with the specified node name
log_info "Running Docker container with node name $NODE_NAME..."
docker run -d --name analog -p 9944:9944 -p 30403:30303 -v /var/lib/analog:/data analoglabs/timechain \
    --base-path /data \
    --rpc-external \
    --unsafe-rpc-external \
    --rpc-cors all \
    --name "$NODE_NAME" \
    --telemetry-url 'wss://telemetry.analog.one/submit 9' \
    --rpc-methods Unsafe || {
    log_error "Failed to run Docker container."
    exit 1
}

# Display logs from the running container
log_info "Displaying logs from the running Docker container 'docker logs -f analog'"
