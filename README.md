# NFT Staking Yield Vault

This repository contains a professional-grade NFT Staking system. It allows users to stake their NFTs (ERC-721) into a secure vault to accrue governance or utility tokens (ERC-20) over time.

## Architecture
The system consists of a primary Staking Controller that interfaces with both an NFT collection and a Reward Token contract. 

* **Fixed Yield:** Earn a specific amount of tokens per block/second per NFT.
* **Safe Transfer:** Uses `onERC721Received` to ensure the contract can handle incoming tokens.
* **Gas Optimized:** Efficient storage mapping to minimize transaction costs during mass staking.

## Deployment Guide
1. Deploy your **Reward Token** (ERC-20).
2. Deploy your **NFT Collection** (ERC-721).
3. Deploy the **NFTStaking** contract, passing the addresses of the two tokens above as constructor arguments.
4. Transfer Reward Tokens to the Staking contract to fund the yield pool.

## Security Note
This contract uses OpenZeppelin's `ReentrancyGuard` to prevent common exploit patterns in DeFi.
