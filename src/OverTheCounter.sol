// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOverTheCounter, OTCInfo} from "src/IOverTheCounter.sol";
import {SafeTransferLib, ERC20} from "solmate/utils/SafeTransferLib.sol";

/// @title OverTheCounter
/// @dev A contract for facilitating direct trades between two parties
contract OverTheCounter is IOverTheCounter {
    using SafeTransferLib for ERC20;

    /// @dev A mapping of order hashes to an expiry timestamp
    mapping(bytes32 => uint256) public orderbook;

    /// @notice Initiates a trade by adding the trade information to the order book
    /// @dev Only the trade initiator can initiate a trade
    /// @param trade The trade information
    /// @param expiry The expiration time of the trade order
    function initiate(OTCInfo memory trade, uint256 expiry) external {
        if (trade.initiator != msg.sender) revert NotInitiator();
        if (trade.want == address(0)) revert ZeroAddress();
        if (trade.have == address(0)) revert ZeroAddress();
        if (expiry < block.timestamp) revert InvalidExpiry();
        bytes32 orderhash = keccak256(abi.encode(trade));
        if (orderbook[orderhash] != 0) revert OrderExists();
        orderbook[orderhash] = expiry;
        emit TradeInitiated(
            trade.initiator,
            trade.counterParty,
            trade.have,
            trade.want,
            trade.haveAmount,
            trade.wantAmount,
            expiry
        );
    }

    /// @notice Revokes a trade by deleting the trade information from the order book
    /// @dev Only the trade initiator can revoke a trade
    /// @param trade The trade information
    function revoke(OTCInfo calldata trade) external {
        bytes32 orderhash = keccak256(abi.encode(trade));
        if (trade.initiator != msg.sender) revert NotInitiator();

        delete orderbook[orderhash];
        emit TradeRevoked(
            trade.initiator,
            trade.counterParty,
            trade.have,
            trade.want,
            trade.haveAmount,
            trade.wantAmount
        );
    }

    /// @notice Facilitates a trade by transferring tokens between the two parties
    /// @dev Deletes the trade information from the order book once the trade is complete
    /// @param trade The trade information
    function swap(OTCInfo calldata trade) external {
        bytes32 orderhash = keccak256(abi.encode(trade));
        uint256 expiry = orderbook[orderhash];
        if (expiry == 0) revert OrderDoesntExist();
        if (expiry < block.timestamp) revert OrderExpired();
        delete orderbook[orderhash];

        address counterParty = trade.counterParty == address(0) ? msg.sender : trade.counterParty;
        if (msg.sender != counterParty) revert NotCounterParty();

        ERC20(trade.have).safeTransferFrom(trade.initiator, counterParty, trade.haveAmount);
        ERC20(trade.want).safeTransferFrom(counterParty, trade.initiator, trade.wantAmount);
        emit TradeSwapped(
            trade.initiator,
            trade.counterParty,
            trade.have,
            trade.want,
            trade.haveAmount,
            trade.wantAmount
        );
    }

    /// @notice Updates a trade by deleting the old trade information from the order book and adding
    /// the new trade information
    /// @dev Only the trade initiator can update a trade
    /// @param oldTrade The old trade information
    /// @param newTrade The new trade information
    /// @param expiry The expiration time of the trade order
    function update(OTCInfo calldata oldTrade, OTCInfo calldata newTrade, uint256 expiry)
        external
    {
        bytes32 orderhash = keccak256(abi.encode(oldTrade));
        if (oldTrade.initiator != msg.sender) revert NotInitiator();
        if (newTrade.initiator != msg.sender) revert NotInitiator();
        if (newTrade.want == address(0)) revert ZeroAddress();
        if (newTrade.have == address(0)) revert ZeroAddress();
        delete orderbook[orderhash];

        if (expiry < block.timestamp) revert InvalidExpiry();
        orderhash = keccak256(abi.encode(newTrade));
        orderbook[orderhash] = expiry;
        emit TradeUpdated(
            newTrade.initiator,
            newTrade.counterParty,
            newTrade.have,
            newTrade.want,
            newTrade.haveAmount,
            newTrade.wantAmount,
            expiry
        );
    }
}
