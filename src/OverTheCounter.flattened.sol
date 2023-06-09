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

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap
/// (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances
/// must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate
/// (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the
/// destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That
/// responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(ERC20 token, address from, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the or() call in the
                    // surrounding and() call or else returndatasize() will be zero during the
                    // computation.
                    call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
                )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the or() call in the
                    // surrounding and() call or else returndatasize() will be zero during the
                    // computation.
                    call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
                )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(ERC20 token, address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success :=
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                    // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                    // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                    // Counterintuitively, this call must be positioned second to the or() call in the
                    // surrounding and() call or else returndatasize() will be zero during the
                    // computation.
                    call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
                )
        }

        require(success, "APPROVE_FAILED");
    }
}

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
