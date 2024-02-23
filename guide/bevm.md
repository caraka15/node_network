# BEVM Node Auto Installation Guide

## System Requirements

| Component      | Requirement           |
|----------------|-----------------------|
| System         | Ubuntu 20.04+         |
| CPU            | Minimum 4 cores       |
| Memory         | Minimum 16GB RAM      |
| Storage        | Minimum 300GB SSD     |

## Installation Steps

1. Download the `bevm-install.sh` script using the following command:

    ```bash
    wget https://raw.githubusercontent.com/caraka15/node_network/main/bevm/bevm-install.sh
    ```

2. Provide executable permissions to the script using the following command:

    ```bash
    chmod +x bevm-install.sh
    ```

3. Run the script using the following command:

    ```bash
    ./bevm-install.sh
    ```

4. Follow the on-screen instructions provided by the script to complete the installation process.

5. Once the installation is complete, you can monitor the node's activity using the command:

    ```bash
    tail -f node/log/bevm.log
    ```

## Contribution

If you encounter any issues or wish to contribute, please open an [issue](https://github.com/caraka15/node_network/issues) or submit a pull request to the [repository](https://github.com/caraka15/node_network).

## License

Distributed under the MIT License. See `LICENSE` for more information.
