# Gaianet Node

## Quick Start

Install the default node software stack with a single line of command on Mac, Linux, or Windows WSL.

```bash
curl -sSfL 'https://github.com/GaiaNet-AI/gaianet-node/releases/latest/download/install.sh' | bash
```

Then, follow the prompt on your screen to set up the environment path. The command line will begin with `source`.

## Initialize the Node

Initialize the node. It will download the model files and vector database files specified in the `$HOME/gaianet/config.json` file, and it could take a few minutes since the files are large.

```bash
gaianet init
```

## Start the Node

Start the node.

```bash
gaianet start
```

## Check Your Device ID

To check your device ID, use the following command:

```bash
gaianet info
```

## Save Your Address, Keystore, and Password

Open the `nodeid.json` file to save your Address, Keystore, and Password.

```bash
nano gaianet/nodeid.json
```

Here’s a tutor bot auto-send chat message in English for running the Gaianet node:

---

**Running Gaianet Node Auto send chat AI**

1. **Clone the Repository**

   ```bash
   git clone https://github.com/iyogz/gaian
   ```

2. **Navigate to the Directory**

   ```bash
   cd gaian
   ```

3. **Edit Configuration**

   Open `gaian.js` with a text editor and replace `NodeIdGaiaMu` with your Gaianet node ID. Save the file afterward.

   ```bash
   nano gaian.js
   ```

4. **Install Dependencies**

   ```bash
   npm i
   ```

5. **Run the Node**

   ```bash
   node gaian.js
   ```

   **Note:** Remember to run this in `screen` or another terminal multiplexer to keep it running continuously.

   You can expect an increase of 50k-100k throughputs per day.

**Special Thanks**

Thanks to tutor @yoghie for the guidance. As a token of appreciation, please give a star to the GitHub repository:

[https://github.com/iyogz/gaianet](https://github.com/iyogz/gaianet)

---
