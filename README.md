# Mystery Airdrop — Confidential Allowlist & Claim with FHEVM

## Overview
Mystery Airdrop is a confidential airdrop system built with Zama’s FHEVM.  
Per-user allocations and claim amounts are stored as encrypted values (`euint64`).  
Only the user can decrypt their own remaining allocation.

## Features
- Encrypted per-user allocations and claims
- Confidential remaining balance (`allocation - claimed`)
- Over-claim protection via fail-closed selection
- No plaintext amounts in events or storage

## Tech Stack
- Solidity + FHEVM
- Hardhat + TypeScript
- Zama SepoliaConfig for FHE integration

## Tests
- Owner sets encrypted allocations
- User claims within allocation
- Over-claim resolves to zero without leaking data

## License
MIT
