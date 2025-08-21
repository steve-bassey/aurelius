# Aurelius Protocol - Fractional NFT Finance

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Clarity Version](https://img.shields.io/badge/Clarity-v3-blue.svg)](https://docs.stacks.co/clarity)
[![Tests](https://img.shields.io/badge/Tests-Vitest-green.svg)](https://vitest.dev/)

## Overview

Aurelius is a pioneering NFT financial protocol that bridges collectible culture with institutional-grade DeFi mechanics on the Stacks blockchain. The protocol introduces collateral-backed minting, programmable fractionalization, and automated staking rewards for long-term value creation, designed for both high-value asset holders and community investors.

### Key Features

- **Collateral-Backed Minting**: Every NFT requires 150% STX collateralization
- **Fractional Ownership**: Split NFTs into tradeable shares
- **Integrated Marketplace**: Built-in trading with automated fee distribution
- **Staking Rewards**: 5% annual yield for staked NFTs
- **Overflow Protection**: Mathematical safeguards against arithmetic errors
- **Institutional Grade**: Robust error handling and access controls

## Architecture

The Aurelius protocol consists of four core modules:

### 1. NFT Core Operations

- **Minting**: Collateral-backed NFT creation with metadata validation
- **Transfers**: Secure ownership transfers with recipient validation
- **Supply Management**: Automated token ID generation and tracking

### 2. Marketplace Module

- **Listing Creation**: Set sale prices with ownership verification
- **Purchase Execution**: Atomic buy operations with fee distribution
- **State Management**: Active/inactive listing tracking

### 3. Fractional Ownership Module

- **Share Transfers**: Transfer fractional ownership between accounts
- **Balance Tracking**: Per-token, per-owner share accounting
- **Overflow Protection**: Safe arithmetic operations

### 4. Staking & Yield Module

- **Staking Engine**: Lock NFTs to earn yield
- **Reward Calculation**: Block-based yield accumulation
- **Claim Mechanism**: Automated reward distribution

## Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Min Collateral Ratio | 150% | Required STX backing for minting |
| Protocol Fee | 2.5% | Marketplace transaction fee |
| Annual Yield Rate | 5% | Staking reward percentage |
| Blocks Per Year | 52,560 | Used for yield calculations |

## Smart Contract Interface

### Core Functions

#### `mint-nft`

```clarity
(mint-nft (uri (string-ascii 256)) (collateral uint))
```

Mint a new NFT with required collateral backing.

#### `transfer-nft`

```clarity
(transfer-nft (token-id uint) (recipient principal))
```

Transfer complete NFT ownership to another address.

#### `list-nft`

```clarity
(list-nft (token-id uint) (price uint))
```

Create a marketplace listing for an NFT.

#### `purchase-nft`

```clarity
(purchase-nft (token-id uint))
```

Buy an NFT from the marketplace with automatic fee handling.

#### `stake-nft`

```clarity
(stake-nft (token-id uint))
```

Stake an NFT to begin earning yield rewards.

#### `unstake-nft`

```clarity
(unstake-nft (token-id uint))
```

Unstake an NFT and claim accumulated rewards.

#### `transfer-shares`

```clarity
(transfer-shares (token-id uint) (recipient principal) (share-amount uint))
```

Transfer fractional ownership shares to another account.

### Read-Only Functions

#### `get-token-info`

```clarity
(get-token-info (token-id uint))
```

Retrieve complete token metadata and state.

#### `get-listing`

```clarity
(get-listing (token-id uint))
```

Get marketplace listing information.

#### `get-fractional-shares`

```clarity
(get-fractional-shares (token-id uint) (owner principal))
```

Check fractional ownership balance.

#### `calculate-rewards`

```clarity
(calculate-rewards (token-id uint))
```

Calculate current staking rewards for a token.

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `err-owner-only` | Operation restricted to contract owner |
| 101 | `err-not-token-owner` | Caller is not the token owner |
| 102 | `err-insufficient-balance` | Insufficient balance for operation |
| 103 | `err-invalid-token` | Token does not exist |
| 104 | `err-listing-not-found` | Marketplace listing not found |
| 105 | `err-invalid-price` | Price must be greater than zero |
| 106 | `err-insufficient-collateral` | Insufficient STX for collateral |
| 107 | `err-already-staked` | Token is already staked |
| 108 | `err-not-staked` | Token is not currently staked |
| 109 | `err-invalid-percentage` | Invalid percentage value |
| 110 | `err-invalid-uri` | Invalid metadata URI |
| 111 | `err-invalid-recipient` | Invalid transfer recipient |
| 112 | `err-overflow` | Arithmetic overflow detected |

## Development Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) v2.0+
- [Node.js](https://nodejs.org/) v18+
- [Git](https://git-scm.com/)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/steve-bassey/aurelius.git
   cd aurelius
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Verify setup**

   ```bash
   clarinet check
   ```

### Testing

The project uses Vitest with Clarinet SDK for comprehensive testing:

```bash
# Run all tests
npm test

# Run tests with coverage and cost analysis
npm run test:report

# Watch mode for development
npm run test:watch
```

### Contract Validation

```bash
# Check contract syntax and analysis
clarinet check

# Format contract code
clarinet fmt

# Generate documentation
clarinet docs
```

## Network Deployment

### Devnet (Local Development)

```bash
clarinet integrate
```

### Testnet Deployment

```bash
clarinet deployment generate --testnet
clarinet deployment apply --testnet
```

### Mainnet Deployment

```bash
clarinet deployment generate --mainnet
clarinet deployment apply --mainnet
```

## Usage Examples

### Basic NFT Operations

```javascript
// Mint an NFT with 1000 STX collateral
const mintTx = makeContractCall({
  contractAddress: "SP...",
  contractName: "aurelius",
  functionName: "mint-nft",
  functionArgs: [
    stringAsciiCV("https://metadata.example.com/1"),
    uintCV(1000000000) // 1000 STX in microSTX
  ],
  senderKey: privateKey
});

// List NFT for sale
const listTx = makeContractCall({
  contractAddress: "SP...",
  contractName: "aurelius",
  functionName: "list-nft",
  functionArgs: [
    uintCV(1), // token-id
    uintCV(500000000) // 500 STX price
  ],
  senderKey: privateKey
});
```

### Staking Operations

```javascript
// Stake NFT to earn yield
const stakeTx = makeContractCall({
  contractAddress: "SP...",
  contractName: "aurelius",
  functionName: "stake-nft",
  functionArgs: [uintCV(1)],
  senderKey: privateKey
});

// Check accumulated rewards
const rewards = await callReadOnlyFunction({
  contractAddress: "SP...",
  contractName: "aurelius",
  functionName: "calculate-rewards",
  functionArgs: [uintCV(1)]
});
```

## Security Considerations

- **Collateral Requirements**: All NFTs must maintain 150% collateralization
- **Access Controls**: Strict ownership verification for all operations
- **Overflow Protection**: Mathematical safeguards prevent arithmetic errors
- **State Validation**: Comprehensive checks prevent invalid state transitions
- **Recipient Validation**: Prevents transfers to contract addresses

## Gas Optimization

The contract implements several gas optimization strategies:

- **Batch Operations**: Efficient data structure updates
- **Early Returns**: Fail-fast validation patterns
- **Minimal Storage**: Optimized data map structures
- **Read-Only Caching**: Reduced redundant computations

## Roadmap

- [ ] **V2.0**: Cross-chain bridge integration
- [ ] **V2.1**: Advanced yield strategies
- [ ] **V2.2**: Governance token launch
- [ ] **V2.3**: Insurance mechanism
- [ ] **V3.0**: Layer 2 scaling solution

## Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built on [Stacks](https://stacks.co) blockchain
- Powered by [Clarity](https://clarity-lang.org) smart contracts
- Tested with [Clarinet](https://github.com/hirosystems/clarinet)
