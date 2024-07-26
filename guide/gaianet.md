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
