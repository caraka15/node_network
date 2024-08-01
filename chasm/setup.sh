#!/bin/bash

# Define log function for pretty output
log() {
    local type="$1"
    local message="$2"
    local color
    case "$type" in
        INFO) color="\033[0;32m" ;; # Green
        ERROR) color="\033[0;31m" ;; # Red
        *) color="\033[0m" ;;       # Default
    esac
    echo -e "${color}${type}: ${message}\033[0m"
}

# Update and install required packages
log INFO "Updating package lists and installing required packages..."
sudo apt-get update && sudo apt-get install -y nano vim curl docker.io

# Install Docker if not already installed
log INFO "Checking if Docker is installed..."
if ! command -v docker &> /dev/null; then
    log INFO "Docker not found. Installing Docker..."
    sudo apt-get install -y docker.io
else
    log INFO "Docker is already installed."
fi

# Function to prompt user for .env values
prompt_env() {
    read -p "Enter PORT [default: 3001]: " PORT
    PORT=${PORT:-3001}

    read -p "Enter LOGGER_LEVEL [default: debug]: " LOGGER_LEVEL
    LOGGER_LEVEL=${LOGGER_LEVEL:-debug}

    read -p "Enter ORCHESTRATOR_URL [default: https://orchestrator.chasm.net]: " ORCHESTRATOR_URL
    ORCHESTRATOR_URL=${ORCHESTRATOR_URL:-https://orchestrator.chasm.net}

    read -p "Enter SCOUT_NAME [leave blank if not applicable]: " SCOUT_NAME
    read -p "Enter SCOUT_UID [leave blank if not applicable]: " SCOUT_UID
    read -p "Enter WEBHOOK_API_KEY [leave blank if not applicable]: " WEBHOOK_API_KEY
    read -p "Enter WEBHOOK_URL [e.g., http://123.123.123.123:3001/]: " WEBHOOK_URL

    read -p "Enter PROVIDERS [default: groq]: " PROVIDERS
    PROVIDERS=${PROVIDERS:-groq}

    read -p "Enter MODEL [default: gemma2-9b-it]: " MODEL
    MODEL=${MODEL:-gemma2-9b-it}

    read -p "Enter GROQ_API_KEY [leave blank if not applicable]: " GROQ_API_KEY
    read -p "Enter OPENROUTER_API_KEY [leave blank if not applicable]: " OPENROUTER_API_KEY
    read -p "Enter OPENAI_API_KEY [leave blank if not applicable]: " OPENAI_API_KEY

    # Write to .env file
    cat <<EOL > .env
PORT=$PORT
LOGGER_LEVEL=$LOGGER_LEVEL

# Chasm
ORCHESTRATOR_URL=$ORCHESTRATOR_URL
SCOUT_NAME=$SCOUT_NAME
SCOUT_UID=$SCOUT_UID
WEBHOOK_API_KEY=$WEBHOOK_API_KEY
WEBHOOK_URL=$WEBHOOK_URL

# Chosen Provider (groq, openai)
PROVIDERS=$PROVIDERS
MODEL=$MODEL
GROQ_API_KEY=$GROQ_API_KEY

# Optional
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY
EOL

    log INFO ".env file created with provided values."
}

# Prompt for .env values
log INFO "Setting up .env file..."
prompt_env

# Pull Docker image
log INFO "Pulling the Docker image..."
docker pull chasmtech/chasm-scout:latest

# Run Docker container
log INFO "Running Docker container..."
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout chasmtech/chasm-scout


# Test server response
log INFO "Testing server response..."
curl -s localhost:3001 | grep -q "OK" && log INFO "Server response test passed." || log ERROR "Server response test failed."

# Test LLM functionality
log INFO "Testing LLM functionality..."
source ./.env
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $WEBHOOK_API_KEY" \
     -d '{"body":"{\"model\":\"gemma2-9b-it\",\"messages\":[{\"role\":\"system\",\"content\":\"You are a helpful assistant.\"}]}"}' \
     $WEBHOOK_URL


log INFO "Setup complete. Please verify the LLM functionality output above."
# Verify server status
log INFO "check your logs node 'docker logs scout' "