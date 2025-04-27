// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IBlocklistUpgradeable {
    error BlocklistUpgradeable__Blocked(bytes32 account);

    event Blocklist_Added(bytes32 indexed account);
    event Blocklist_Removed(bytes32 indexed account);

    function isBlocked(address account) external view returns (bool);
    function isBlocked(bytes32 account) external view returns (bool);
    function addToBlocklist(address account) external;
    function addToBlocklist(bytes32 account) external;
    function removeFromBlocklist(address account) external;
    function removeFromBlocklist(bytes32 account) external;
}
