## Rift Protocol 🌌

Rift Protocol is an advanced, privacy-centric DeFi suite built natively on the Seismic Network (a privacy-preserving EVM Layer 1).

Our flagship product is a highly optimized, multi-asset Escrow Protocol designed to bring trustless, secure, and confidential settlements to the Web3 ecosystem. By leveraging Seismic's TEE (Trusted Execution Environment) architecture, Rift ensures that sensitive deal data and user interactions remain completely shielded.

## 🌐 Website: riftprotocol.xyz

## 📖 Overview (The Escrow Protocol)

The Rift Escrow Protocol allows two parties (a caller and a listener) to safely exchange multiple asset types in a single, atomic transaction. If the conditions are met, the smart contract settles the assets; if the deadline passes or conditions fail, users can safely cancel and refund their assets.

## Key Features

Multi-Asset Support: Seamlessly handles Native tokens, ERC20 tokens, and ERC721 (NFTs) within the same deal pair structure (cryptoDeal).

Extreme Gas Optimization: Written with deep EVM mechanics in mind. The protocol utilizes inline assembly extensively for slot packing (e.g., bit-shifting buyer and seller addresses into a single bytes32 slot) and memory-based hashing (mload(0x40)).

Advanced Memory Management: Handles complex dynamic arrays (structs within structs) in memory before efficiently flushing them to storage to bypass excessive sstore gas costs.

via-IR Compilation: The architecture relies on via-IR compiler pipelines to apply aggressive Yul-level optimizations and bypass the EVM's "Stack Too Deep" limitations during cryptographic operations.

## 🏗️ Technical Architecture & Seismic Integration

Building on Seismic requires a paradigm shift in how we handle state and events. Rift Protocol is designed to integrate flawlessly with Seismic's infrastructure:

Shielded State (suint, sbytes): Future privacy iterations of the contract use Seismic's native shielded types and CSTORE/CLOAD opcodes to hide deal details from the public ledger.

Encrypted Event Logs: The protocol integrates with seismic-viem on the frontend. We utilize cryptographic precompiles (ECDH, HKDF, and AES-GCM) to emit encrypted logs (StealthTransfer), ensuring that only the rightful participants can trial-decrypt and read their deal status.

Smart Access Control: Deals are tied strictly to authenticated wallet signatures, preventing unauthorized state reads.

## 🚀 Roadmap (The Privacy Hub)

While the Escrow Protocol is our foundational layer, Rift's ultimate vision is to become the premier Privacy Hub on the Seismic network.

Phase 1 (Current): Advanced Multi-Asset Escrow Protocol.

Phase 2 (Upcoming): Private Mixer - Allowing users to anonymize their token trails utilizing Seismic's zero-knowledge-like privacy guarantees without the ZK computational overhead.

Phase 3 (Future): Confidential Liquidity AMM - A decentralized exchange where liquidity pools, slippage paths, and trade volumes are completely hidden, eliminating MEV and front-running attacks by design.

## 🛠️ Development & Deployment

This project is built using sforge (Seismic's fork of Foundry).bash

Install dependencies
sforge install

Build the project (via-IR enabled)
sforge build --via-ir

Run local test node
sanvil

## 📄 License
This project is licensed under the MIT License.
