// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint64, externalEuint64 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/// @title Mystery Airdrop — Confidential Allowlist & Claim with FHEVM
/// @notice Per-user allocations and claims are stored as encrypted values (euint64).
///         Only the user can decrypt their own remaining allocation.
contract ConfAirdrop is SepoliaConfig {
    address public owner;
    bool public frozen; // when true, owner can no longer update allocations (optional safety switch)

    // Encrypted per-user allocation and claimed amounts
    mapping(address => euint64) private _allocation;
    mapping(address => euint64) private _claimed;

    event AllocationSet(address indexed user);       // amount hidden
    event AllocationBatchSet(uint256 count);         // amounts hidden
    event Claimed(address indexed user);             // amount hidden
    event Frozen();

    error NotOwner();
    error FrozenAirdrop();
    error InvalidUser();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Freeze the airdrop configuration (owner cannot change allocations anymore).
    function freeze() external onlyOwner {
        frozen = true;
        emit Frozen();
    }

    /// @notice Set (or top-up) a single user's encrypted allocation.
    /// @dev `encryptedAmt` is verified/cast by FHE.fromExternal.
    function setAllocation(
        address user,
        externalEuint64 encryptedAmt,
        bytes calldata inputProof
    ) external onlyOwner {
        if (frozen) revert FrozenAirdrop();
        if (user == address(0)) revert InvalidUser();

        euint64 amt = FHE.fromExternal(encryptedAmt, inputProof);
        _allocation[user] = FHE.add(_allocation[user], amt);

        FHE.allowThis(_allocation[user]);
        FHE.allow(_allocation[user], user);

        emit AllocationSet(user);
    }

    /// @notice Batch set allocations for multiple users (same encrypted amount per user or pre-encrypted per user).
    /// @dev For simplicity here we use one encrypted value applied to all provided users.
    function batchSetAllocation(
        address[] calldata users,
        externalEuint64 encryptedAmt,
        bytes calldata inputProof
    ) external onlyOwner {
        if (frozen) revert FrozenAirdrop();

        euint64 amt = FHE.fromExternal(encryptedAmt, inputProof);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (user == address(0)) revert InvalidUser();

            _allocation[user] = FHE.add(_allocation[user], amt);
            FHE.allowThis(_allocation[user]);
            FHE.allow(_allocation[user], user);
        }
        emit AllocationBatchSet(users.length);
    }

    /// @notice Claim an encrypted amount from caller's allocation. Fails closed if over-claim.
    function claim(
        externalEuint64 encryptedAmt,
        bytes calldata inputProof
    ) external {
        address user = msg.sender;

        // requested amount
        euint64 req = FHE.fromExternal(encryptedAmt, inputProof);

        // remaining = allocation - claimed
        euint64 remaining = FHE.sub(_allocation[user], _claimed[user]);

        // If req <= remaining -> toClaim = req else 0 (fail-closed)
        euint64 toClaim = FHE.select(FHE.le(req, remaining), req, FHE.asEuint64(0));

        // Update claimed
        _claimed[user] = FHE.add(_claimed[user], toClaim);

        // Maintain access policies so user & contract can read their own figures
        FHE.allowThis(_claimed[user]);
        FHE.allow(_claimed[user], user);

        // Also re-allow allocation (not strictly needed every time, but good for UX)
        FHE.allowThis(_allocation[user]);
        FHE.allow(_allocation[user], user);

        emit Claimed(user);
    }

    /// @notice View your encrypted allocation.
    function getMyAllocation() external view returns (euint64) {
        return _allocation[msg.sender];
    }

    /// @notice View your encrypted claimed amount.
    function getMyClaimed() external view returns (euint64) {
        return _claimed[msg.sender];
    }

    /// @notice View your encrypted remaining amount: allocation - claimed.
    function getMyRemaining() external view returns (euint64) {
        return FHE.sub(_allocation[msg.sender], _claimed[msg.sender]);
    }
}
