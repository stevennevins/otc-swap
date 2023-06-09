// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OTCInfo {
    address have;
    address want;
    uint256 haveAmount;
    uint256 wantAmount;
    address initiator;
    address counterParty;
}

interface IOverTheCounter {
    event TradeInitiated(
        address indexed initiator,
        address indexed counterParty,
        address have,
        address want,
        uint256 haveAmount,
        uint256 wantAmount,
        uint256 expiry
    );
    event TradeRevoked(
        address indexed initiator,
        address indexed counterParty,
        address have,
        address want,
        uint256 haveAmount,
        uint256 wantAmount
    );
    event TradeSwapped(
        address indexed initiator,
        address indexed counterParty,
        address have,
        address want,
        uint256 haveAmount,
        uint256 wantAmount
    );
    event TradeUpdated(
        address indexed initiator,
        address indexed counterParty,
        address have,
        address want,
        uint256 haveAmount,
        uint256 wantAmount,
        uint256 expiry
    );

    error NotInitiator();
    error InvalidExpiry();
    error OrderExists();
    error OrderDoesntExist();
    error OrderExpired();
    error NotCounterParty();
    error ZeroAddress();

    function initiate(OTCInfo calldata trade, uint256 expiry) external;

    function revoke(OTCInfo calldata trade) external;

    function swap(OTCInfo calldata trade) external;

    function update(OTCInfo calldata oldTrade, OTCInfo calldata newTrade, uint256 expiry)
        external;

    function orderbook(bytes32 orderhash) external view returns (uint256 expiry);
}
