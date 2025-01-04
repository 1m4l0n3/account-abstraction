//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test,console} from "../lib/forge-std/src/Test.sol";
import {MinimalAccountDeploy} from "../script/MinimalAccountDeploy.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {ERC20Mock} from "../lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract MinimalAccountTest is Test {
    MinimalAccountDeploy private deployer;
    MinimalAccount private minimalAccount;
    HelperConfig public helperConfig;
    ERC20Mock private usdc;
    address public randomUser;

    function setUp() external {
        deployer = new MinimalAccountDeploy();
        (helperConfig, minimalAccount) = deployer.deployMinimalAccount();
        usdc = new ERC20Mock();
        randomUser = makeAddr("randomUser");
    }

    function testOwnerCanExecuteCommands() external {
        assertEq(usdc.balanceOf(address(minimalAccount)),0);
        address destination = address(usdc);
        uint256 value = 0;
        uint256 amount = 1e18;

        bytes memory callData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);

        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination,value,callData);

        assertEq(usdc.balanceOf(address(minimalAccount)),amount);
    }

    function testNonOwenerCantExecuteACommand() external {
        assertEq(usdc.balanceOf(address(minimalAccount)),0);
        address destination = address(usdc);
        uint256 value = 0;
        uint256 amount = 1e18;

        bytes memory callData = abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),amount);

        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(destination,value,callData);
    }
}