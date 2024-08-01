# Chasm Inference Scout Setup Guide

## Introduction

Welcome to the Chasm Inference Scout setup guide! This document will walk you through the steps needed to install and run Inference Scout on your server. Whether you are new or experienced, this guide is designed to help you get started quickly.

Inference Scout runs inference tasks provided by Chasm's Orchestrator, enabling you to use advanced language models and contribute to the Chasm Network.

## Prerequisites

### API Keys

- **Groq API Key**: Obtain this from the [Groq Console](https://console.groq.com/keys){:target="\_blank"}.
- **Openrouter API Key** (Optional): Get it from the [Openrouter](https://openrouter.ai/settings/keys){:target="\_blank"}.
- **SCOUT_UID and WEBHOOK_API_KEY**: Retrieve these from the [Chasm Website](https://scout.chasm.net/private-mint){:target="\_blank"}.

### Server Specifications

<table>
  <thead>
    <tr>
      <th>Specification</th>
      <th>Minimum Requirement</th>
      <th>Suggested Requirement</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>CPU</strong></td>
      <td>1 vCPU</td>
      <td>2 vCPU</td>
    </tr>
    <tr>
      <td><strong>RAM</strong></td>
      <td>1GB</td>
      <td>4GB</td>
    </tr>
    <tr>
      <td><strong>Disk Space</strong></td>
      <td>20GB</td>
      <td>50GB SSD</td>
    </tr>
    <tr>
      <td><strong>IP</strong></td>
      <td>Static IP</td>
      <td>Static IP</td>
    </tr>
  </tbody>
</table>

### Obtaining SCOUT_UID and WEBHOOK_API_KEY

1. Visit [Chasm's Scout Mint Page](https://scout.chasm.net/private-mint){:target="\_blank"}.
2. Visit [Groq API Website](https://console.groq.com/keys){:target="\_blank"} and [Openrouter Website](https://openrouter.ai/settings/keys){:target="\_blank"} to get Groq API.
3. Click on **Mint (scout)** "you need 0.1 MNT mainnet".
4. Log in and retrieve your webhook API key and UID.

## Auto-Install Setup

To automate the installation process, follow these steps:

1. **Save the Auto-Install Script**

   ```bash
   wget https://raw.githubusercontent.com/caraka15/node_network/main/chasm/setup.sh
   ```

2. **Make the Script Executable**

   ```bash
   chmod +x setup.sh
   ```

3. **Run the Script**

   Execute the script to start the installation:

   ```bash
   ./setup.sh
   ```

   The script will:

   - Install necessary packages and Docker if not already installed.
   - Prompt you to enter required values for the `.env` file.
   - Pull the Docker image and run the Docker container.
   - Verify the server status and test the server response.

## Restart Docker Container (If Needed)

If you need to restart the Docker container, use the following commands:

```bash
docker stop scout
docker rm scout
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout chasmtech/chasm-scout
```

## Verify Scout Ranking

Check your scout ranking on the [Leaderboard](https://scout.chasm.net/leaderboard?page=1){:target="\_blank"}. Note that the node status might take up to an hour to update.

## Monitor Scout Performance

To monitor the performance of your scout, run:

```bash
docker stats scout
```

## Troubleshooting

If you encounter any issues, check the Docker logs with:

```bash
docker logs scout
```

This guide should help you set up and manage your Chasm Inference Scout efficiently. If you need further assistance, feel free to refer to Chasm's official documentation or support channels.
