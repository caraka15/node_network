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

- To update the validator node to the latest version, use the following command:

  ```bash
  sudo systemctl stop pwr && \
  sudo pkill java && \
  cd /root/pwr && \
  sudo rm -rf validator.jar config.json blocks && \
  wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/validator.jar && \
  wget https://github.com/pwrlabs/PWR-Validator-Node/raw/main/config.json && \
  sudo systemctl start pwr
  ```

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
