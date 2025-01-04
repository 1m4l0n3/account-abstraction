//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {IEntryPoint} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccount is IAccount, Ownable {
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);

    IEntryPoint private i_entryPoint;

    modifier requireFromEntryPoint() {
        if ( msg.sender != address(i_entryPoint) ){
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }
    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }
    
    constructor(address _entryPoint) Ownable(msg.sender){
        i_entryPoint = IEntryPoint(_entryPoint);
    }
    
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        uint256 validationData = _validateUserOp(userOp,userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function execute(address destination, uint256 value, bytes calldata functionData) external  {
        (bool success, bytes memory result) = destination.call{value: value}(functionData);
        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
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