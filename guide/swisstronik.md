# Swisstronik Testnet 2.0

![Swisstronik Image 2](https://github.com/caraka15/node_network/blob/main/images/swisstronik-guide.jpg?raw=true)

## Guide Task

### Prerequisites

1. **Clone the Repository**

   ```sh
   git clone https://github.com/caraka15/hardhatSwisstronik.git
   cd hardhatSwisstronik
   ```

2. **Install Dependencies**

   ```sh
   npm install
   ```

3. **Create a `.env` File**
   ```sh
   nano .env
   ```
   Add your private key to the `.env` file:
   ```
   PRIVATE_KEY=your_private_key_here
   ```
   Use `Ctrl+X` to save.

---

## Deploy a Simple Contract Using Hardhat

### 1. Deploy `Deploy.sol`

- Before running, you can edit your token name.

- Run the deployment script:
  ```sh
  npx hardhat run scripts/deploy.js --network swisstronik
  ```

### 2. Set Message

- Run the script to set the message:
  ```sh
  npx hardhat run scripts/setMessage.js --network swisstronik
  ```

### 3. Get Message

- Run the script to get the message:
  ```sh
  npx hardhat run scripts/getMessage.js --network swisstronik
  ```

---

## Mint 100 ERC-20 Tokens

### 1. Deploy `TokenERC20.sol`

- Run the deployment script:
  ```sh
  npx hardhat run scripts/deployERC20.js --network swisstronik
  ```

### 2. Mint ERC-20 Tokens

- Create `mintERC20.js` in the `scripts` directory.
- Run the script to mint tokens:
  ```sh
  npx hardhat run scripts/mintERC20.js --network swisstronik
  ```

### 3. Transfer Tokens

- Run the script to transfer tokens:
  ```sh
  npx hardhat run scripts/transfer.js --network swisstronik
  ```

### 4. Check Balance (Optional)

- Run the script to check balance:
  ```sh
  npx hardhat run scripts/balanceOf.js --network swisstronik
  ```

---

## Mint an ERC-721 Token

### 1. Deploy `TokenERC721.sol`

- Before running, you can edit your token name.
- Run the deployment script:
  ```sh
  npx hardhat run scripts/deployERC721.js --network swisstronik
  ```

### 2. Mint ERC-721 Tokens

- Run the script to mint an NFT:
  ```sh
  npx hardhat run scripts/mintERC721.js --network swisstronik
  ```

### 3. Check Balance (Optional)

- Run the script to check balance:
  ```sh
  npx hardhat run scripts/balanceOf.js --network swisstronik
  ```

---

## Mint a PERC-20 Token

### 1. Deploy `TokenPERC20.sol`

- Before running, you can edit your token name.
- Run the deployment script:
  ```sh
  npx hardhat run scripts/deployPERC20.js --network swisstronik
  ```

### 2. Mint PERC-20 Tokens

- Run the script to mint tokens:
  ```sh
  npx hardhat run scripts/mintPERC20.js --network swisstronik
  ```

### 3. Transfer Tokens

- Run the script to transfer tokens:
  ```sh
  npx hardhat run scripts/transferPERC20.js --network swisstronik
  ```

---

## Mint a Private NFT

### 1. Deploy `privateNFT.sol`

- Before running, you can edit your token name.
- Run the deployment script:
  ```sh
  npx hardhat run scripts/deployprivateNFT.js --network swisstronik
  ```

### 2. Mint Private NFT Tokens

- Run the script to mint tokens:
  ```sh
  npx hardhat run scripts/mintprivateNFT.js --network swisstronik
  ```

---

![Swisstronik Image 1](https://github.com/caraka15/node_network/blob/main/images/swisstronik-participate.jpg?raw=true)

---

Guide and task are not finished yet, wait for the next update.
