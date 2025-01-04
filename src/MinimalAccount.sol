//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";

contract MinimalAccount is IAccount, Ownable {

    constructor() Ownable(msg.sender){}

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {
        uint256 validationData = _validateUserOp(userOp,userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function _validateUserOp(PackedUserOperation memory userOp,bytes32 userOpHash) internal view returns(uint256 validationData) {
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSignedMessageHash,userOp.signature);
        if ( signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        (bool success, ) = payable(msg.sender).call{value: missingAccountFunds,gas: type(uint256).max}("");
    }
}