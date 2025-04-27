// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

interface IBlocklistUpgradeable {
    error BlocklistUpgradeable__Blocked(address account);

    event Blocklist_Added(address indexed account);
    event Blocklist_Removed(address indexed account);

    function isBlocked(address account) external view returns (bool);
    function addToBlocklist(address account) external;
    function removeFromBlocklist(address account) external;
}
