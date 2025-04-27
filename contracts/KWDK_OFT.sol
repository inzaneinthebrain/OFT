// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { OFTUpgradeable } from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import { BlocklistUpgradeable } from "./BlocklistUpgradeable.sol";

contract KWDK is OFTUpgradeable, BlocklistUpgradeable {
    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _delegate) public initializer {
        __OFT_init(_name, _symbol, _delegate);
        __Blocklist_init();
        __Ownable_init(_delegate);
    }

    function decimals() public pure override returns (uint8) {
        return 3;
    }

    function sharedDecimals() public pure override returns (uint8) {
        return 3;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (isBlocked(from)) {
            revert BlocklistUpgradeable__Blocked(from);
        }
        super._update(from, to, value);
    }
}
