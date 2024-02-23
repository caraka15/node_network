#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed."
    read -p "Do you want to install Docker? (y/n): " install_docker
    if [ "$install_docker" == "y" ]; then
        echo "Installing Docker..."
        # Install Docker
        curl -fsSL https://get.docker.com | bash -s docker
        echo "Docker has been installed successfully."
    else
        echo "Skipping Docker installation. Exiting."
        exit 1
    fi
else
    echo "Docker is already installed."
fi

# Create directory and move into it
echo "Creating directory 'node'..."
mkdir node && cd node
echo "Directory 'node' created."

# Prompt user for validator name
read -p "Enter the name of the validator: " validator_name

# Create config.json file with provided validator name
echo "Creating config.json file..."
cat <<EOF >config.json
{
  "chain": "testnet",
  "log-dir": "/log",
  "enable-console-log": true,
  "no-mdns": true,
  "validator": true,
  "unsafe-rpc-external": true,
  "offchain-worker": "when-authority",
  "rpc-methods": "unsafe",
  "log": "info,runtime=info",
  "port": 30333,
  "rpc-port": 8087,
  "pruning": "archive",
  "db-cache": 2048,
  "name": "$validator_name",
  "base-path": "/data",
  "telemetry-url": "wss://telemetry-testnet.bevm.io/submit 1",
  "bootnodes": []
}
EOF
echo "config.json file created."

# Pull Docker image
echo "Pulling Docker image btclayer2/bevm:testnet-v0.1.3..."
sudo docker pull btclayer2/bevm:testnet-v0.1.3
echo "Docker image pulled successfully."

# Run Docker container
echo "Running Docker container..."
sudo docker run -d --restart always --name bevm-node \
  -p 8087:8087 -p 30333:30333 \
  -v $PWD/config.json:/config.json -v $PWD/data:/data \
  -v $PWD/log:/log -v $PWD/keystore:/keystore \
  btclayer2/bevm:testnet-v0.1.3 /usr/local/bin/bevm \
  --config /config.json
echo "Node is now running."
echo "Check your logs with: tail -f /node/log/bevm.log"
