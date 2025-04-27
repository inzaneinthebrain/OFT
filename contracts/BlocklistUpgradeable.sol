// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IBlocklistUpgradeable } from "./interfaces/IBlocklistUpgradeable.sol";

/**
 * @title BlocklistUpgradeable
 * @notice Implements blocklist configuration and calculation.
 */
abstract contract BlocklistUpgradeable is Initializable, OwnableUpgradeable, IBlocklistUpgradeable {
    struct BlocklistStorage {
        mapping(address => bool) isBlocked;
    }

    // keccak256(abi.encode(uint256(keccak256("layerzerov2.storage.blocklist")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BLOCKLIST_STORAGE_LOCATION =
        0xd3878e6a0651ed1175c76a318a040b750e51db85dc4ff0398fe981d084922a00;

    /**
     * @dev The init function is intentionally left empty and does not initialize Ownable.
     * This is to ensure that Ownable can be initialized in the child contract to accommodate
     * potential different versions of Ownable that might be used.
     */
    function __Blocklist_init() internal onlyInitializing {}

    function __Blocklist_init_unchained() internal onlyInitializing {}

    function _getBlocklistStorage() internal pure returns (BlocklistStorage storage $) {
        assembly {
            $.slot := BLOCKLIST_STORAGE_LOCATION
        }
    }

    function isBlocked(address account) public view returns (bool) {
        return _getBlocklistStorage().isBlocked[account];
    }

    function addToBlocklist(address account) public onlyOwner {
        emit Blocklist_Added(account);
        _getBlocklistStorage().isBlocked[account] = true;
    }

    function removeFromBlocklist(address account) public onlyOwner {
        emit Blocklist_Removed(account);
        _getBlocklistStorage().isBlocked[account] = false;
    }
}
