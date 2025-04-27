// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BlocklistUpgradeable } from "../contracts/BlocklistUpgradeable.sol";
import { IBlocklistUpgradeable } from "../contracts/interfaces/IBlocklistUpgradeable.sol";
import { UnsafeUpgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

import { Test, console } from "forge-std/Test.sol";

contract BlocklistUpgradeableImpl is BlocklistUpgradeable {
    function initialize(address _owner) public initializer {
        __Blocklist_init();
        __Ownable_init(_owner);
    }
}

contract BlocklistUpgradeableTest is Test {
    BlocklistUpgradeable public blocklist;

    address public block_user = makeAddr("block_user");

    bytes32 public constant BLOCKLIST_STORAGE_SLOT = 0xd3878e6a0651ed1175c76a318a040b750e51db85dc4ff0398fe981d084922a00;

    function setUp() public {
        address impl = address(new BlocklistUpgradeableImpl());
        address proxy = UnsafeUpgrades.deployTransparentProxy(
            impl,
            address(this),
            abi.encodeCall(BlocklistUpgradeableImpl.initialize, (address(this)))
        );
        blocklist = BlocklistUpgradeable(proxy);
    }

    function test_storage_slot() public pure {
        bytes32 storageSlot = keccak256(abi.encode(uint256(keccak256("layerzerov2.storage.blocklist")) - 1)) &
            ~bytes32(uint256(0xff));
        assertEq(BLOCKLIST_STORAGE_SLOT, storageSlot);
    }

    function test_blocking() public {
        vm.expectEmit(true, true, true, true);
        emit IBlocklistUpgradeable.Blocklist_Added(blocklist.addressToBytes32(block_user));
        blocklist.addToBlocklist(block_user);
        assertTrue(blocklist.isBlocked(block_user));
    }

    function test_unblocking() public {
        blocklist.addToBlocklist(block_user);
        blocklist.removeFromBlocklist(block_user);
        assertFalse(blocklist.isBlocked(block_user));
    }
}
