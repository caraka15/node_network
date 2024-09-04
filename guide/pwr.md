# PWR Chain Validator Node & RPC Node Guide

## Validator Node Guide

**Important Note:** This is the inaugural testnet launch. While we strive for perfection, there might be unforeseen issues. We appreciate all feedback, bug reports, or any other issues reported in our Discord server.

### Requirements

- **CPU:** 1 vCPU
- **Memory:** 1 GB RAM
- **Disk:** 25 GB HDD or higher
- **Open TCP Ports:** 8231, 8085
- **Open UDP Port:** 7621

### Setup on Ubuntu Server

### 1. Download and Run the Auto-Install Script

- Download and run the script directly from GitHub:

  ```bash
  curl -O https://raw.githubusercontent.com/caraka15/node_network/main/pwr/auto-install-pwr.sh
  chmod +x auto-install-pwr.sh
  sudo ./auto-install-pwr.sh
  ```

### 2. Check Logs

- To monitor the validator node logs, use the following command:

  ```bash
  journalctl -fu pwr -o cat
  ```

- **Note:** This command shows real-time logs from the validator node service. Use it to check for errors or confirm that your node is running correctly.

### 3. Check Validator Address

- After running the script, it will take a minute for the validator service to start. Fetch your validator address using:

  ```bash
  curl -s http://localhost:8085/address/
  ```

- **Note:** If the address is not immediately available, wait a few minutes and rerun the curl command.

- **Output Example:**

  ```bash
  Your address: 0x.....
  ```

### 4. Get Faucet PWR Coins

- Once you have your validator address, go to our Discord server and navigate to the `#bot-commands` channel.

- **Command:** Use the following command in the `#bot-commands` channel to request faucet PWR Coins:

  ```plaintext
  /claim <YourValidatorAddress>
  ```

- Replace `<YourValidatorAddress>` with the address you obtained from the previous step.

### 5. Update Validator Node

This script allows you to easily update the `config.json` file or both the `config.json` and `validator.jar` files on your Ubuntu server. You can run this script from any directory on your system using the `update-pwr` command.

## Installation Steps

### 1. Download and Install the Script

Download the `update-pwr` script directly from GitHub and copy it to `/usr/local/bin`:

```bash
sudo wget -O /usr/local/bin/update-pwr https://raw.githubusercontent.com/caraka15/node_network/main/update-pwr.sh
```

### 2. Grant Execute Permissions

Ensure the script has execute permissions:

```bash
sudo chmod +x /usr/local/bin/update-pwr
```

## How to Use

To run the update, simply type the following command from any directory:

```bash
update-pwr
```

You will be prompted to choose between updating only the `config.json` file or updating both the `validator.jar` and `config.json` files:

```bash
Choose update option:
1. Update config.json only
2. Update both validator and config.json
```

- Select `1` to update only the `config.json`.
- Select `2` to update both the `validator.jar` and `config.json`.

### 6. Check Private Key

- To retrieve your private key, run the following commands:

  ```bash
  cd /root/pwr
  sudo java -jar validator.jar get-private-key /root/pwr/password
  ```

- **Note:** Keep your private key secure and do not share it with anyone.

### Additional Notes

- The script creates a systemd service file named `pwr.service` to manage the validator node.
- The validator node will synchronize with the blockchain but will not assume validator responsibilities until it possesses staked PWR Coins.
- Ensure that you have your validator address ready before requesting faucet PWR Coins on Discord.
