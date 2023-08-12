# Cross-chain NFT

## Project Description:
The project implements Cross-chain NFTs spanning Goerli, Optimism, Base and Zora chains.

Users mint an Random NFT on Layer1 through VRF, which triggers minting on mirrored Layer2 contracts to solve the problem that VRF does not support Layer2.

NFT maintains a 1:1 mapping across chains. Users can freely conduct transactions, while the framework synchronizes the state.

The implementation of cross-chain NFTs can improve the security of transactions. As the NFT ownership is synchronized across multiple chains, it increases the protection and tamper-resistance for the NFT. This can reduce the risks of NFTs being tampered with or stolen.

The architecture focuses on UX abstractions and provides the infrastructure for true multi-chain NFT interoperability.


## How it's Made

The core contracts are implemented in Solidity, using Foundry as the development framework.

Foundry provides tools like for compiling and deploying contracts and some unit test tool etc.

The core contracts are implemented in Solidity, utilizing OpenZeppelin and Chainlink VRF. They are deployed across Ethereum, Optimism, Base and Zora.

The @eth-optimism/sdk enables cross-chain operations like message relaying between contracts.

The front-end uses Next.js as the React framework. React provides component-driven UI development.

Moralis and Web3UIKit enable blockchain interactions like wallet connectivity and contract calls.

Tailwind CSS is used for styling and layouts.

IPFS provides decentralized storage and synchronization of NFT metadata across chains.