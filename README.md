# Account Abstraction Project

## Overview

This project demonstrates the implementation of Account Abstraction in Ethereum smart contracts, focusing on a minimal account model. Account Abstraction allows for more flexible and programmable account management by enabling smart contract-based accounts instead of traditional Externally Owned Accounts (EOAs). This approach facilitates features like meta-transactions, custom authentication schemes, and enhanced security models.

## Key Features

- **MinimalAccount Contract**: A streamlined smart contract representing a user account with essential functionalities.
- **Deployment Scripts**: Automated scripts for deploying the `MinimalAccount` contract and related configurations.
- **User Operation Execution**: Scripts to send packed user operations, showcasing how to interact with the account abstraction model.
- **Comprehensive Testing**: Test cases to ensure the correct functionality of the `MinimalAccount` contract and associated operations.

## Contracts and Scripts

### MinimalAccount.sol

A smart contract that represents a minimal user account with essential functionalities. Key functions include:

- **`validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, address aggregator, uint256 missingAccountFunds)`**: Validates a user operation, ensuring it meets the necessary criteria for execution.
- **`execute(address dest, uint256 value, bytes calldata func)`**: Executes a transaction to a specified destination with a given value and function call data.
- **`executeBatch(address[] calldata dest, bytes[] calldata func)`**: Executes multiple transactions in a batch, allowing for efficient processing of multiple operations.

### HelperConfig.s.sol

A script that provides configuration helpers for deployment and testing. It includes functions to retrieve network configurations, addresses, and other essential parameters required during deployment and execution.

### MinimalAccountDeploy.s.sol

A deployment script for the `MinimalAccount` contract. It automates the process of deploying the contract to a specified network, ensuring that all necessary parameters are correctly configured.

### SendPackedUserOp.s.sol

A script designed to send packed user operations. It demonstrates how to create and send user operations in the context of account abstraction, providing a practical example of interacting with the `MinimalAccount` contract.

### MinimalAccountTest.t.sol

A test suite for the `MinimalAccount` contract. It includes various test cases to verify the correct functionality of the contract's features, ensuring robustness and reliability.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```


### Deploy

```shell
$ forge script script/MinimalAccountDeploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
$ forge script script/SendPackedUserOp.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
