//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test,console} from "../lib/forge-std/src/Test.sol";
import {MinimalAccountDeploy} from "../script/MinimalAccountDeploy.s.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp} from "../script/SendPackedUserOp.s.sol";
import {MessageHashUtils} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "../lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "../lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

contract MinimalAccountTest is Test {
    MinimalAccountDeploy private deployer;
    MinimalAccount private minimalAccount;
    SendPackedUserOp private sendPackedUserOp;
    HelperConfig public helperConfig;
    ERC20Mock private usdc;
    address public randomUser;
    uint256 public amount;

    function setUp() external {
        deployer = new MinimalAccountDeploy();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        sendPackedUserOp = new SendPackedUserOp();
        usdc = new ERC20Mock();
        randomUser = makeAddr("randomUser");
        amount = 1e18;
    }

    function testOwnerCanExecuteCommands() external {
        assertEq(usdc.balanceOf(address(minimalAccount)),0);
        address destination = address(usdc);
        uint256 value = 0;

        bytes memory callData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination,value,callData);

        assertEq(usdc.balanceOf(address(minimalAccount)),amount);
    }

    function testNonOwnerCantExecuteACommand() external {
        assertEq(usdc.balanceOf(address(minimalAccount)),0);
        address destination = address(usdc);
        uint256 value = 0;

        bytes memory callData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);

        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(destination,value,callData);
    }

    function testRecoverSignedUp() public {
        assertEq(usdc.balanceOf(address(minimalAccount)),0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory callData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector,destination,value,callData);

        PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeCallData,helperConfig.getConfig());
        bytes32 userOperationHash =  IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOperationHash);
        address actualSigner = ECDSA.recover(digest,packedUserOp.signature);

        assertEq(actualSigner,minimalAccount.owner());
    }

    function testValidateUserOps() external {
        address destination = address(usdc);
        uint256 value = 0;
        uint256 missingFund = 1e18;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);
        bytes memory executeCallData = abi.encodeWithSelector(MinimalAccount.execute.selector,destination,value,functionData);
        PackedUserOperation memory userOp = sendPackedUserOp.generateSignedUserOperation(executeCallData,helperConfig.getConfig());
        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(userOp);

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validation = minimalAccount.validateUserOp(userOp,userOpHash,missingFund);
        assertEq(validation,0);
    }
}