// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { IKWDK_OFT } from "./interfaces/IKWDK_OFT.sol";

import { OFTUpgradeable } from "@layerzerolabs/oft-evm-upgradeable/contracts/oft/OFTUpgradeable.sol";
import { SendParam, MessagingFee, OFTReceipt, MessagingReceipt } from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";
import { BlocklistUpgradeable } from "./BlocklistUpgradeable.sol";

/**
 * @title KWDK_OFT
 * @notice A contract that implements the KWDK_OFT interface.
 * @dev This contract is a child of OFTUpgradeable and BlocklistUpgradeable.
 */
contract KWDK is OFTUpgradeable, BlocklistUpgradeable, IKWDK_OFT {
    constructor(address _lzEndpoint) OFTUpgradeable(_lzEndpoint) {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, address _delegate) public initializer {
        __OFT_init(_name, _symbol, _delegate);
        __Blocklist_init();
        __Ownable_init(_delegate);
    }

    /**
     * @notice Returns the number of decimals of the token.
     * @dev This token is linked to the fiat currency of Kuwait which has 3 decimal places.
     * @dev This is also called "local decimals" in layerzero documentation.
     * @return The number of decimals.
     */
    function decimals() public pure override returns (uint8) {
        return 3;
    }

    /**
     * @notice Returns the number of shared decimals of the token.
     * @dev The shared decimals is used by layerzero on cross-chain calls.
     * @dev The following invariant must be maintained: shared decimals <= local decimals
     * @dev This is the "scaling factor" in a cross-chain call.
     * @return The number of decimals.
     */
    function sharedDecimals() public pure override returns (uint8) {
        return 3;
    }

    /**
     * @notice Mints a new token.
     * @dev This function is only callable by the owner.
     * @param to The address to mint the token to.
     * @param amount The amount of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns a token.
     * @dev This function is only callable by the owner.
     * @param from The address to burn the token from.
     * @param amount The amount of tokens to burn.
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    /**
     * @notice Combines the logic of updating the balance of a user and checking if the user is blocked.
     * @param from The address to update the balance from.
     * @param to The address to update the balance to.
     * @param value The amount of tokens to update the balance by.
     */
    function _update(address from, address to, uint256 value) internal override {
        if (isBlocked(from)) {
            revert BlocklistUpgradeable__Blocked(addressToBytes32(from));
        }
        super._update(from, to, value);
    }

    /**
     * @notice Sends a message to the LayerZero endpoint. This is extended with blocklist checks.
     * @dev Since the base send function is external we can't call super.send() here.
     * @param _sendParam The parameters for the send operation.
     * @param _fee The fee for the send operation.
     * @param _refundAddress The address to refund the fee to.
     * @return msgReceipt The receipt of the send operation.
     * @return oftReceipt The receipt of the OFT operation.
     */
    function send(
        SendParam calldata _sendParam,
        MessagingFee calldata _fee,
        address _refundAddress
    ) external payable override returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) {
        if (isBlocked(_sendParam.to)) {
            revert BlocklistUpgradeable__Blocked(_sendParam.to);
        }
        // @dev Applies the token transfers regarding this send() operation.
        // - amountSentLD is the amount in local decimals that was ACTUALLY sent/debited from the sender.
        // - amountReceivedLD is the amount in local decimals that will be received/credited to the recipient on the remote OFT instance.
        (uint256 amountSentLD, uint256 amountReceivedLD) = _debit(
            msg.sender,
            _sendParam.amountLD,
            _sendParam.minAmountLD,
            _sendParam.dstEid
        );

        // @dev Builds the options and OFT message to quote in the endpoint.
        (bytes memory message, bytes memory options) = _buildMsgAndOptions(_sendParam, amountReceivedLD);

        // @dev Sends the message to the LayerZero endpoint and returns the LayerZero msg receipt.
        msgReceipt = _lzSend(_sendParam.dstEid, message, options, _fee, _refundAddress);
        // @dev Formulate the OFT receipt.
        oftReceipt = OFTReceipt(amountSentLD, amountReceivedLD);

        emit OFTSent(msgReceipt.guid, _sendParam.dstEid, msg.sender, amountSentLD, amountReceivedLD);
    }
}
