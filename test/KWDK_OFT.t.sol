// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { KWDK } from "../contracts/KWDK_OFT.sol";
import { IBlocklistUpgradeable } from "../contracts/interfaces/IBlocklistUpgradeable.sol";

import { UnsafeUpgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Test, console } from "forge-std/Test.sol";

contract KWDK_OFTTest is Test {
    address public constant polygon_endpoint = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 public constant polygon_eid = 30109;

    KWDK public kwdk;

    address public block_user = makeAddr("block_user");
    address public alice = makeAddr("alice");

    function setUp() public {
        vm.createSelectFork(getChain("polygon").rpcUrl);
        address impl = address(new KWDK(polygon_endpoint));

        address proxy = UnsafeUpgrades.deployTransparentProxy(
            impl,
            msg.sender,
            abi.encodeCall(KWDK.initialize, ("KWDK", "KWDK", msg.sender))
        );

        kwdk = KWDK(proxy);
        deal(proxy, msg.sender, 1 ether);
    }

    function test_deployment() public view {
        assertEq(kwdk.name(), "KWDK");
        assertEq(kwdk.symbol(), "KWDK");
        assertEq(kwdk.endpoint().eid(), polygon_eid);
    }

    function test_decimals() public view {
        assertGe(kwdk.decimals(), kwdk.sharedDecimals());
        assertEq(kwdk.decimals(), 3);
        assertEq(kwdk.sharedDecimals(), 3);
    }

    function test_blocklist() public {
        vm.startPrank(msg.sender);
        kwdk.addToBlocklist(block_user);
        vm.stopPrank();

        deal(address(kwdk), block_user, 100);
        vm.startPrank(block_user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IBlocklistUpgradeable.BlocklistUpgradeable__Blocked.selector,
                kwdk.addressToBytes32(block_user)
            )
        );
        kwdk.transfer(alice, 100);
        vm.stopPrank();

        vm.startPrank(msg.sender);
        kwdk.removeFromBlocklist(block_user);
        vm.stopPrank();

        vm.startPrank(block_user);
        kwdk.transfer(alice, 100);
        vm.stopPrank();

        assertEq(kwdk.balanceOf(alice), 100);
        assertEq(kwdk.balanceOf(block_user), 0);
    }
}
