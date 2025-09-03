# 🎁 Mystery Airdrop — Confidential Allowlist & Claim with FHEVM

## ✨ What is Mystery Airdrop?
Mystery Airdrop is a privacy-preserving token distribution system built with Zama’s FHEVM.  
It lets protocols run airdrops where both **eligibility** and **claim amounts** stay encrypted, so only the claimer learns their allocation.

## 🔒 Key Advantages
- 🕵️ **Confidential allowlist** — eligibility proofs are verified privately on-chain.  
- 🎲 **Hidden claim amounts** — allocations are visible only to recipients.  
- ⛓️ **Fair & sybil-resistant** — harder to game or copy allocations.  
- ⚡ **EVM compatible** — deployable on Ethereum and L2s.  
- 🧪 **Covered by tests** — end-to-end verification & claim flows.

## 📂 Project Structure
mystery-airdrop/  
├── contracts/  
│   └── MysteryAirdrop.sol  
├── test/  
│   └── MysteryAirdrop.spec.ts  
├── hardhat.config.ts  
├── package.json  
├── .gitignore  
├── LICENSE  
└── README.md  

## 🚀 Quick Start
1) Install dependencies  
   npm install

2) Compile contracts  
   npx hardhat compile

3) Run tests  
   npx hardhat test

## 🎯 Use Cases
- Private community airdrops with hidden allocations.  
- Fair token launches that avoid mempool snooping.  
- Confidential reward claims or vesting unlocks.

## 📝 License
This project is licensed under the MIT License.
