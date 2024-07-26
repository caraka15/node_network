# Swisstronik Testnet 2.0

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
   you can use ctrl+x to save

## Deploy a Simple Contract Using Hardhat

### 1. Deploy `Deploy.sol`

- before run you can edit your token name

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

## Mint an ERC-721 Token

### 1. Deploy `TokenERC721.sol`

- before run you can edit your token name
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
  guide and task not finished yet, wait for next update
