//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "../lib/forge-std/src/Script.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract SendPackedUserOp is Script {
    function run() public {}

    function generateSignedUserOperation(bytes memory callData,HelperConfig.NetworkConfig memory config) public view returns(PackedUserOperation memory){
        // 1. Generate the unsigned data
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory userOp = _generateUnSignedUserOperation(callData,config.account,nonce);

        //2. Get OpsHash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        ///3. Sign it
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == 31337) {
            uint256 anvilPrivateKey = vm.parseUint((vm.envString("ANVIL_DEFAULT_PRIVATE_KEY")));
            (v, r, s) = vm.sign(anvilPrivateKey,digest);
        }
        else {
            (v, r, s) = vm.sign(config.account,digest);
        }
        userOp.signature = abi.encodePacked(r,s,v);
        return userOp;
    }

    function _generateUnSignedUserOperation(bytes memory callData, address sender, uint256 nonce) internal pure returns(PackedUserOperation memory){
        uint128 verificationGasLimit = 16777216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verificationGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }

}