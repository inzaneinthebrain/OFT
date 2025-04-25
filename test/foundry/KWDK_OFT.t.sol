// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { KWDK } from "../../contracts/KWDK_OFT.sol";
import { UnsafeUpgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Test, console } from "forge-std/Test.sol";

contract KWDK_OFTTest is Test {
    address public constant polygon_endpoint = 0x1a44076050125825900e736c501f859c50fE728c;
    uint32 public constant polygon_eid = 30109;

    KWDK public kwdk;

    function setUp() public {
        vm.createSelectFork(getChain("polygon").rpcUrl);
        address impl = address(new KWDK(polygon_endpoint));

        address proxy = UnsafeUpgrades.deployTransparentProxy(
            impl,
            msg.sender,
            abi.encodeCall(KWDK.initialize, ("KWDK", "KWDK", msg.sender))
        );

        kwdk = KWDK(proxy);
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
}
