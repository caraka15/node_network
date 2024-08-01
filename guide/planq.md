# Setup for Mainnet Planq

![Planq Network](https://user-images.githubusercontent.com/108979536/210136942-caa7f157-c189-4d6b-8278-0bb86f42ba2c.png)

### Guide Source

- **Planq Network**
- **Explorer**: [Planq Explorer](https://explorer.planq.network)

## Hardware Requirements

### Minimum Hardware Requirements

- **CPUs**: 4x CPUs; the faster clock speed the better
- **RAM**: 8GB
- **Storage**: 100GB (SSD or NVME)

### Recommended Hardware Requirements

- **CPUs**: 8x CPUs; the faster clock speed the better
- **RAM**: 64GB
- **Storage**: 1TB (SSD or NVME)

## Set Up Your Planq Validator

### Option 1: Automatic Setup

You can set up your Planq validator in a few minutes using the automated script below. It will prompt you to input your validator node name:

```bash
wget -O planq.sh https://raw.githubusercontent.com/appieasahbie/planq/main/planq.sh && chmod +x planq.sh && ./planq.sh
```

### Post Installation

When the installation is finished, load the variables into the system:

```bash
source $HOME/.bash_profile
```

Next, check if your validator is syncing blocks:

```bash
planqd status 2>&1 | jq .SyncInfo
```

### Create Wallet

- To create a new wallet, use:

  ```bash
  planqd keys add $WALLET
  ```

- (OPTIONAL) To recover your wallet using a seed phrase:

  ```bash
  planqd keys add $WALLET --recover
  ```

- To import your wallet from MetaMask:

  ```bash
  planqd keys unsafe-import-eth-key <wallet-name> <private-key-eth> --keyring-backend file
  ```

- To get the current list of wallets:

  ```bash
  planqd keys list
  ```

(Save wallet info in your notepad)

### Add Wallet and Valoper Address into Variables

```bash
PLANQD_WALLET_ADDRESS=$(planqd keys show $WALLET -a)
PLANQD_VALOPER_ADDRESS=$(planqd keys show $WALLET --bech val -a)
echo 'export PLANQD_WALLET_ADDRESS='${PLANQD_WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export PLANQD_VALOPER_ADDRESS='${PLANQD_VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile
```

### Fund Your Wallet

To create a validator, you need to fund your wallet with mainnet tokens. Please refer to this guide to get mainnet tokens: [Planq Airdrop](https://docs.planq.network/about/airdrop.html) and import your wallet from MetaMask.

### Create Validator

Before creating a validator, ensure that you have at least 1 Planq (1 Planq = 1,000,000,000,000 aplanq) and your node is synchronized.

- To check your wallet balance:

  ```bash
  planqd query bank balances $PLANQD_WALLET_ADDRESS
  ```

If your wallet does not show any balance, your node may still be syncing. Wait until it finishes syncing and then continue.

To create your validator:

```bash
planqd tx staking create-validator \
  --amount 1000000000000aplanq \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.05" \
  --min-self-delegation "1" \
  --pubkey $(planqd tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $PLANQ_CHAIN_ID \
  --gas="1000000" \
  --gas-prices="30000000000aplanq" \
  --gas-adjustment="1.15"
```

### Security

To protect your keys, follow these basic security rules:

- Set up SSH keys for authentication. [Tutorial on SSH keys](https://www.digitalocean.com/community/tutorials/how-to-set-up-ssh-keys--2)

- Basic firewall security:

  ```bash
  sudo ufw status
  sudo ufw default allow outgoing
  sudo ufw default deny incoming
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw allow ${PLANQ_PORT}656,${PLANQ_PORT}660/tcp
  sudo ufw enable
  ```

### Check Your Validator Key

```bash
[[ $(planqd q staking validator $PLANQD_VALOPER_ADDRESS -oj | jq -r .consensus_pubkey.key) = $(planqd status | jq -r .ValidatorInfo.PubKey.value) ]] && echo -e "\n\e[1m\e[32mTrue\e[0m\n" || echo -e "\n\e[1m\e[31mFalse\e[0m\n"
```

- Get a list of validators:

  ```bash
  planqd q staking validators -oj --limit=3000 | jq '.validators[] | select(.status=="BOND_STATUS_BONDED")' | jq -r '(.tokens|tonumber/pow(10; 6)|floor|tostring) + " \t " + .description.moniker' | sort -gr | nl
  ```

### Useful Commands

- **Service Management**

  - Check logs:

    ```bash
    journalctl -fu planqd -o cat
    ```

  - Start service:

    ```bash
    sudo systemctl start planqd
    ```

  - Stop service:

    ```bash
    sudo systemctl stop planqd
    ```

  - Restart service:

    ```bash
    sudo systemctl restart planqd
    ```

### Node Info

- Synchronization info:

  ```bash
  planqd status 2>&1 | jq .SyncInfo
  ```

- Validator info:

  ```bash
  planqd status 2>&1 | jq .ValidatorInfo
  ```

- Node info:

  ```bash
  planqd status 2>&1 | jq .NodeInfo
  ```

- Show node ID:

  ```bash
  planqd tendermint show-node-id
  ```

### Wallet Operations

- List of wallets:

  ```bash
  planqd keys list
  ```

- Recover wallet:

  ```bash
  planqd keys add $WALLET --recover
  ```

- Delete wallet:

  ```bash
  planqd keys delete $WALLET
  ```

- Get wallet balance:

  ```bash
  planqd query bank balances $PLANQD_WALLET_ADDRESS
  ```

- Transfer funds:

  ```bash
  planqd tx bank send $PLANQD_WALLET_ADDRESS <TO_PLANQ_WALLET_ADDRESS> 1000000000000aplanq
  ```

- Voting:

  ```bash
  planqd tx gov vote 1 yes --from $WALLET --chain-id=$PLANQ_CHAIN_ID
  ```

### Staking, Delegation, and Rewards

- Delegate stake:

  ```bash
  planqd tx staking delegate $PLANQD_VALOPER_ADDRESS 1000000000000aplanq --from=$WALLET --chain-id=$PLANQ_CHAIN_ID --gas=auto
  ```

- Redelegate stake from one validator to another:

  ```bash
  planqd tx staking redelegate <srcValidatorAddress> <destValidatorAddress> 1000000000000aplanq --from=$WALLET --chain-id=$PLANQ_CHAIN_ID --gas=auto
  ```

- Withdraw all rewards:

  ```bash
  planqd tx distribution withdraw-all-rewards --from=$WALLET --chain-id=$PLANQ_CHAIN_ID --gas=auto
  ```

- Withdraw rewards with commission:

  ```bash
  planqd tx distribution withdraw-rewards $PLANQD_VALOPER_ADDRESS --from=$WALLET --commission --chain-id=$PLANQ_CHAIN_ID
  ```

### Validator Management

- Edit validator:

  ```bash
  planqd tx staking edit-validator \
   --moniker=$NODENAME \
   --identity=<your_keybase_id> \
   --website="<your_website>" \
   --details="<your_validator_description>" \
   --chain-id=$PLANQ_CHAIN_ID \
   --from=$WALLET
  ```

- Unjail validator:

  ```bash
  planqd tx slashing unjail \
   --broadcast-mode=block \
   --from=$WALLET \
   --chain-id=$PLANQ_CHAIN_ID \
   --gas=auto
  ```

- Delete node:

  This command will completely remove the node from the server. Use at your own risk!

  ```bash
  sudo systemctl stop planqd && \
  sudo systemctl disable planqd && \
  rm /etc/systemd/system/planqd.service && \
  sudo systemctl daemon-reload && \
  cd $HOME && \
  rm -rf planqd && \
  rm -rf .planqd && \
  rm -rf $(which planqd)
  ```
