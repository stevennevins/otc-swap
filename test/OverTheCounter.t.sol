// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {Deploy} from "script/Deploy.s.sol";
import {OTCInfo, IOverTheCounter} from "src/IOverTheCounter.sol";

contract OverTheCounterTest is Test, Deploy {
    address public user0 = address(2);
    address public user1 = address(4);
    MockERC20 public token0;
    MockERC20 public token1;

    OTCInfo public trade = OTCInfo({
        have: address(token0),
        want: address(token1),
        haveAmount: 1 ether,
        wantAmount: 1 ether,
        initiator: user0,
        counterParty: user1
    });

    function setUp() public virtual {
        token0 = new MockERC20("", "", 18);
        token1 = new MockERC20("", "", 18);
        token0.mint(user0, 100 ether);
        token1.mint(user1, 100 ether);
        trade = OTCInfo({
            have: address(token0),
            want: address(token1),
            haveAmount: 1 ether,
            wantAmount: 1 ether,
            initiator: user0,
            counterParty: user1
        });
        Deploy.run();
    }
}

contract Initiate is OverTheCounterTest {
    function test_InitiatesTrade() public {
        vm.prank(user0);
        otc.initiate(trade, block.timestamp + 1);
        assertTrue(otc.orderbook(keccak256(abi.encode(trade))) != 0);
    }

    function test_RevertsIf_NotInitiator() public {
        vm.expectRevert(abi.encodeWithSelector(IOverTheCounter.NotInitiator.selector));
        otc.initiate(trade, block.timestamp + 1);
    }

    function test_RevertsIf_TradeExists() public {}

    function test_RevertsIf_TradeExpired() public {}

    function test_RevertsIf_WantTokenAddress0() public {}

    function test_RevertsIf_HaveTokenAddress0() public {}
}

contract Revoke is OverTheCounterTest {
    function setUp() public override {
        super.setUp();
        vm.prank(user0);
        otc.initiate(trade, block.timestamp + 1);
        assertTrue(otc.orderbook(keccak256(abi.encode(trade))) != 0);
    }

    function test_RevokesTrade() public {
        vm.prank(user0);
        otc.revoke(trade);
    }

    function test_RevertsIf_NotInitiator() public {}
}

contract Swap is OverTheCounterTest {
    function setUp() public override {
        super.setUp();
        vm.prank(user0);
        otc.initiate(trade, block.timestamp + 1);
        assertTrue(otc.orderbook(keccak256(abi.encode(trade))) != 0);
        vm.prank(user0);
        token0.approve(address(otc), 1 ether);
        vm.prank(user1);
        token1.approve(address(otc), 1 ether);
    }

    function test_If_CounterPartySpecified() public {
        vm.prank(user1);
        otc.swap(trade);
        assertEq(token0.balanceOf(user1), 1 ether);
        assertEq(token1.balanceOf(user0), 1 ether);
    }

    function test_If_CounterPartyNotSpecified() public {}

    function test_RevertsIf_AlreadyFilled() public {}

    function test_RevertsIf_NoApprovalCounterParty() public {}

    function test_RevertsIf_NoApprovalInitiator() public {}

    function test_RevertsIf_InsufficientBalanceCounterParty() public {}

    function test_RevertsIf_InsufficientBalanceInitiator() public {}

    function test_RevertsIf_TradeExpired() public {}

    function test_RevertsIf_TradeDoesntExist() public {}
}

contract Update is OverTheCounterTest {
    function setUp() public override {
        super.setUp();
        vm.prank(user0);
        otc.initiate(trade, block.timestamp + 1);
        assertTrue(otc.orderbook(keccak256(abi.encode(trade))) != 0);
    }

    function test_UpdateTrade() public {
        vm.prank(user0);
        otc.update(trade, trade, block.timestamp + 2);
    }

    function test_RevertsIf_NotInitiator() public {}

    function test_RevertsIf_NewExpiryInPast() public {}

    function test_RevertsIf_NewTradeExists() public {}

    function test_RevertsIf_WantTokenAddress0() public {}

    function test_RevertsIf_HaveTokenAddress0() public {}
}
