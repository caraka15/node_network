#!/bin/bash

# Function to print in bold
function print_bold() {
    echo -e "\033[1m$1\033[0m"
}

# Function to print in color
function print_color() {
    echo -e "\033[0;32m$1\033[0m"
}

print_bold "Starting PWR Validator Node Installation..."

# Create the /root/pwr directory and change to that directory
print_color "Creating directory /root/pwr and changing to it..."
mkdir -p /root/pwr
cd /root/pwr

# Update OS
print_color "Updating OS packages..."
sudo apt update

# Install Java
print_color "Installing OpenJDK 19..."
sudo apt install -y openjdk-19-jre-headless

# Install validator node software and config file
print_color "Downloading validator node software..."
wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar -O validator.jar
wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json -O config.json

# Get IP address
IP_ADDRESS=$(hostname -I | awk '{print $1}')
print_color "Detected IP Address: $IP_ADDRESS"

# Prompt for password
print_bold "Enter your desired password:"
read -s PASSWORD
echo $PASSWORD | sudo tee /root/pwr/password > /dev/null

# Prompt for wallet option
print_bold "Choose an option:"
print_color "1. Create new wallet"
print_color "2. Recover existing wallet"
read -p "Enter your choice (1 or 2): " WALLET_OPTION

if [ "$WALLET_OPTION" = "2" ]; then
    print_color "Recovering existing wallet..."
    print_bold "Enter your private key:"
    read -s PRIVATE_KEY
    sudo java -jar validator.jar --import-key $PRIVATE_KEY $PASSWORD
    print_bold "Wallet recovery process completed."
    read -p "Press Enter to continue..."
fi

# Create a systemd service file for the validator node
print_color "Creating systemd service file..."
sudo tee /etc/systemd/system/pwr.service <<EOF
[Unit]
Description=PWR Validator Node
After=network-online.target
Wants=network-online.target

[Service]
User=root
WorkingDirectory=/root/pwr
ExecStart=/usr/bin/java -jar /root/pwr/validator.jar /root/pwr/password $IP_ADDRESS --compression-level 0
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new service file
print_color "Reloading systemd..."
sudo systemctl daemon-reload

# Enable and start the validator service
print_color "Enabling and starting the validator service..."
sudo systemctl enable pwr
sudo systemctl start pwr

# Wait for the service to start and then fetch the address
print_bold "Fetching validator address..."
sleep 60
ADDRESS=$(curl -s http://localhost:8085/address/)

# Print the address or a message if the address is not available
if [ -z "$ADDRESS" ]; then
    print_bold "Address not found. If the address does not appear, wait a few minutes and run 'curl -s http://localhost:8085/address/' to retrieve it."
else
    print_bold "Your address: $ADDRESS"
fi

# Print instruction to check logs
print_bold "To check the logs of the validator node service, use the following command:"
print_color "journalctl -fu pwr -o cat"

print_bold "Installation and setup complete."
