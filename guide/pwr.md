# PWR Chain Validator Node & RPC Node Guide

## Validator Node Guide

**Important Note:** This is the inaugural testnet launch. While we strive for perfection, there might be unforeseen issues. We appreciate all feedback, bug reports, or any other issues reported in our Discord server.

### Requirements

- **CPU:** 1 vCPU
- **Memory:** 1 GB RAM
- **Disk:** 25 GB HDD or higher
- **Open TCP Ports:** 8231, 8085
- **Open UDP Port:** 7621


### 1. Tools PWR

PWR Tools is an all-in-one script for managing PWR validator nodes on Ubuntu servers. Created by CRXA NODE, this tool provides essential functions such as installation, updates, port checking, address retrieval, and private key verification through an easy-to-use menu interface. Supporting both English and Indonesian, PWR Tools can be run from any directory, making it an efficient and practical utility for PWR validator node operators.

`this tools only working if you install node on /pwr folder and use systemctl for service`

### 1. Download and Install the Script

Download the `update-pwr` script directly from GitHub and copy it to `/usr/local/bin`:

```bash
sudo wget -O /usr/local/bin/pwr https://raw.githubusercontent.com/caraka15/node_network/main/pwr/pwr.sh
```

### 2. Grant Execute Permissions

Ensure the script has execute permissions:

```bash
sudo chmod +x /usr/local/bin/pwr
```

## How to Use

To run the update, simply type the following command from any directory:

```bash
pwr
```
![image](https://github.com/user-attachments/assets/26317683-583a-49ae-8415-fff2101a80f2)

### 2. Get Faucet PWR Coins

- Once you have your validator address, go to our Discord server and navigate to the `#bot-commands` channel.

- **Command:** Use the following command in the `#bot-commands` channel to request faucet PWR Coins:

  ```plaintext
  /claim <YourValidatorAddress>
  ```

- Replace `<YourValidatorAddress>` with the address you obtained from the previous step.

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
