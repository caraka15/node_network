<<<<<<< HEAD
# BEVM Node Auto Installation Guide

## System Requirements

<table style="width: 50%;">
  <tr>
    <th>Component</th>
    <th>Requirement</th>
  </tr>
  <tr>
    <td>System</td>
    <td>Ubuntu 18.04+</td>
  </tr>
  <tr>
    <td>CPU</td>
    <td>8 vCPUs (c6i.xlarge)</td>
  </tr>
  <tr>
    <td>Memory</td>
    <td>16 GB (c6i.xlarge)</td>
  </tr>
  <tr>
    <td>Storage</td>
    <td>300 GB storage (NVMe SSD)</td>
  </tr>
  <tr>
    <td>Network Port</td>
    <td>9944</td>
  </tr>
  <tr>
    <td>Network Speed</td>
    <td>At least 500 MBps.</td>
  </tr>
</table>

## Installation Steps

1. Download the `bevm-install.sh` script using the following command:

   ```bash
   wget https://raw.githubusercontent.com/caraka15/node_network/main/analog/analog-install.sh
   ```

2. Provide executable permissions to the script using the following command:

   ```bash
   chmod +x analog-install.sh
   ```

3. Run the script using the following command:

   ```bash
   ./analog-install.sh
   ```

4. Follow the on-screen instructions provided by the script to complete the installation process.

5. Once the installation is complete, you can monitor the node's activity using the command:

   ```bash
   docker logs -f analog
   ```

## Post-Installation Steps

### Check Node Synchronization

After your node has synced, you can check its status on the [Analog Telemetry Dashboard](https://telemetry.analog.one/#/0x0614f7b74a2e47f7c8d8e2a5335be84bdde9402a43f5decdec03200a87c8b943).

### Generate and Register Your Session Keys

1. **Generate Session Keys**

   First, while running the Timechain, connect to the node RPC interface, and execute the following command to generate the keys:

   ```bash
   echo '{"id":1,"jsonrpc":"2.0","method":"author_rotateKeys","params":[]}' | websocat -n1 -B 99999999 ws://127.0.0.1:9944
   ```

   The output will have a hex-encoded "result" field. The string is the concatenation of the three public keys. Save this result for a later step.

2. **Register Session Keys**

   Next, you need to insert the session keys by signing and submitting an extrinsic. This is what associates your Time Node with your validator account.

   - Navigate to [Network > Staking](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.testnet.analog.one#/staking/actions) and click on the **Accounts** tab.
   - Click "Set Session Key" on the bonding account you've generated.
   - Enter the output from `author_rotateKeys` in the field and click "Set Session Key."

### Payouts

- Navigate to [Network > Staking > Payouts](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.testnet.analog.one#/staking/payout), choose an appropriate payout period, and click "Payout" for the bonding account you generated earlier.

## Contribution

If you encounter any issues or wish to contribute, please open an [issue](https://github.com/caraka15/node_network/issues) or submit a pull request to the [repository](https://github.com/caraka15/node_network).

## License

Distributed under the MIT License. See `LICENSE` for more information.
=======
# BEVM Node Auto Installation Guide

## System Requirements

<table style="width: 50%;">
  <tr>
    <th>Component</th>
    <th>Requirement</th>
  </tr>
  <tr>
    <td>System</td>
    <td>Ubuntu 18.04+</td>
  </tr>
  <tr>
    <td>CPU</td>
    <td>8 vCPUs (c6i.xlarge)</td>
  </tr>
  <tr>
    <td>Memory</td>
    <td>16 GB (c6i.xlarge)</td>
  </tr>
  <tr>
    <td>Storage</td>
    <td>300 GB storage (NVMe SSD)</td>
  </tr>
  <tr>
    <td>Network Port</td>
    <td>9944</td>
  </tr>
  <tr>
    <td>Network Speed</td>
    <td>At least 500 MBps.</td>
  </tr>
</table>

## Installation Steps

1. Download the `bevm-install.sh` script using the following command:

   ```bash
   wget https://raw.githubusercontent.com/caraka15/node_network/main/analog/analog-install.sh
   ```

2. Provide executable permissions to the script using the following command:

   ```bash
   chmod +x analog-install.sh
   ```

3. Run the script using the following command:

   ```bash
   ./analog-install.sh
   ```

4. Follow the on-screen instructions provided by the script to complete the installation process.

5. Once the installation is complete, you can monitor the node's activity using the command:

   ```bash
   docker logs -f analog
   ```

## Post-Installation Steps

### Check Node Synchronization

After your node has synced, you can check its status on the [Analog Telemetry Dashboard](https://telemetry.analog.one/#/0x0614f7b74a2e47f7c8d8e2a5335be84bdde9402a43f5decdec03200a87c8b943).

### Generate and Register Your Session Keys

1. **Generate Session Keys**

   First, while running the Timechain, connect to the node RPC interface, and execute the following command to generate the keys:

   ```bash
   echo '{"id":1,"jsonrpc":"2.0","method":"author_rotateKeys","params":[]}' | websocat -n1 -B 99999999 ws://127.0.0.1:9944
   ```

   The output will have a hex-encoded "result" field. The string is the concatenation of the three public keys. Save this result for a later step.

2. **Register Session Keys**

   Next, you need to insert the session keys by signing and submitting an extrinsic. This is what associates your Time Node with your validator account.

   - Navigate to [Network > Staking](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.testnet.analog.one#/staking/actions) and click on the **Accounts** tab.
   - Click "Set Session Key" on the bonding account you've generated.
   - Enter the output from `author_rotateKeys` in the field and click "Set Session Key."

### Payouts

- Navigate to [Network > Staking > Payouts](https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Frpc.testnet.analog.one#/staking/payout), choose an appropriate payout period, and click "Payout" for the bonding account you generated earlier.

## Contribution

If you encounter any issues or wish to contribute, please open an [issue](https://github.com/caraka15/node_network/issues) or submit a pull request to the [repository](https://github.com/caraka15/node_network).

## License

Distributed under the MIT License. See `LICENSE` for more information.
>>>>>>> b5e074e304fa3200716e8a080443047817146f73
