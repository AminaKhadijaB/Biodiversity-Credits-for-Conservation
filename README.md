#  Biodiversity Credits for Conservation

A blockchain-based marketplace for biodiversity credits tied to preserved habitats, helping combat the accelerating loss of biodiversity through economic incentives.

## 🎯 Problem Statement

Biodiversity loss is accelerating globally, and conservation efforts are severely underfunded. Traditional conservation models lack transparent verification and sustainable economic incentives.

## 💡 Solution

Our smart contract creates a marketplace where:
- 🛰️ **Satellite-verified** protected areas generate biodiversity credits
- 🏢 **NGO partnerships** provide professional habitat verification
- 💰 **Credit trading** creates economic incentives for conservation
- 📊 **Transparent tracking** ensures accountability

## ✨ Features

### 🏞️ Habitat Management
- Register new conservation habitats
- Calculate credits based on size and biodiversity score
- Satellite verification through authorized NGOs
- Annual credit minting for verified habitats

### 🤝 NGO Partnerships
- Authorize NGO partners for habitat verification
- Reputation scoring system
- Verification fee structure
- Professional oversight of conservation claims

### 💱 Credit Trading
- Create sell orders for biodiversity credits
- Execute trades with STX payments
- Cancel active trades
- Direct credit transfers between users
- Batch credit transfers for efficient bulk distributions

### 🌍 Carbon Credit Integration
- Register carbon offset projects for verified habitats
- Mint carbon credits based on habitat size and sequestration rates
- Transfer carbon credits between users
- Credit swap functionality (biodiversity ↔ carbon)

### ♻️ Credit Retirement
- Permanently retire biodiversity credits to demonstrate environmental commitment
- Track retired credits per user for transparency and reporting
- Burn credits from circulation to prevent double-counting
- Support corporate sustainability goals and voluntary carbon markets

### 🏦 Credit Staking
- Stake biodiversity credits to earn passive rewards at 5% annual rate
- Automatic reward calculation based on staked amount and time
- Flexible staking and unstaking with reward claiming
- Incentivize long-term credit holding for conservation impact

### 🆙 Habitat Upgrades
- Submit habitat improvement proposals with updated size and biodiversity scores
- NGO-verified upgrades to reflect enhanced conservation efforts
- Automatic recalculation of credit generation rates post-approval
- Transparent tracking of habitat evolution and improvements

## 🚀 Quick Start

### Prerequisites
- [Clarinet](https://docs.hiro.so/stacks/clarinet)
- Node.js (for testing)

### Installation
```bash
git clone <repository-url>
cd Biodiversity-Credits-for-Conservation
npm install
```

### Testing
```bash
npm test
```

### Deployment
```bash
clarinet deploy --testnet
```

## 📖 Usage Guide

### 1. Register a Habitat 🌳
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation register-habitat 
  "Amazon Rainforest Sector 42" 
  u1000  ;; 1000 hectares
  u80)   ;; biodiversity score out of 100
```

### 2. NGO Verification 🔍
Only authorized NGOs can verify habitats:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation verify-habitat 
  u1  ;; habitat-id
  0x1234...)  ;; satellite data hash
```

### 3. Mint Credits 🪙
After verification, habitat owners can mint credits annually:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation mint-credits u1)
```

### 4. Trade Credits 🔄
Create sell orders:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation create-trade 
  u100   ;; credits to sell
  u50)   ;; price per credit in STX
```

Execute trades:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation execute-trade u1)
```

### 5. Transfer Credits 📤
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation transfer-credits
  'SP2ABC...  ;; recipient
  u25)        ;; amount
```

### 6. Batch Transfer Credits 📦
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation batch-transfer-credits
  (list
    {recipient: 'SP2ABC..., amount: u10}
    {recipient: 'SP3DEF..., amount: u20}
  )
)
```

### 7. Register Carbon Project 🌍
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation register-carbon-project
  u1          ;; habitat-id
  u15         ;; carbon tons per hectare per year
  "VCS-REDD") ;; methodology
```

### 8. Mint Carbon Credits ♻️
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation mint-carbon-credits u1)
```

### 9. Swap Credits 🔄
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation swap-credits
  u100)  ;; biodiversity credits to swap for carbon credits (75% conversion rate)
```

### 10. Retire Credits ♻️
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation retire-credits
  u50)  ;; amount of biodiversity credits to permanently retire
```

### 11. Submit Habitat Upgrade 🆙
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation submit-habitat-upgrade
  u1          ;; habitat-id
  u1200       ;; new size in hectares
  u85)        ;; new biodiversity score
```

### 12. Approve Habitat Upgrade ✅
Only authorized NGOs can approve upgrades:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation approve-habitat-upgrade
  u1  ;; upgrade-id
  0x1234...)  ;; satellite data hash
```

### 13. Stake Credits 🏦
Stake biodiversity credits to earn passive rewards:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation stake-credits
  u100)  ;; amount to stake
```

### 14. Claim Staking Rewards 💰
Claim accumulated staking rewards:
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation claim-staking-rewards)
```

### 15. Unstake Credits 🔓
Unstake credits (auto-claims rewards):
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation unstake-credits
  u50)  ;; amount to unstake
```

## 🔍 Read-Only Functions

### Check Balances
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-user-credits 'SP123...)
(contract-call? .Biodiversity-Credits-for-Conservation get-user-carbon-credits 'SP123...)
```

### View Habitat Details
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-habitat u1)
```

### Check Trade Status
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-trade u1)
```

### View Carbon Projects
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-carbon-project u1)
```

### View Contract Statistics
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-contract-info)
```

### Check Retired Credits
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-retired-credits 'SP123...)
```

### View Habitat Upgrade Details
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-habitat-upgrade u1)
```

### Check Stake Information
```clarity
(contract-call? .Biodiversity-Credits-for-Conservation get-stake-info 'SP123...)
```

## 🏗️ Contract Architecture

### Core Components
- **Habitat Registry**: Tracks protected areas and their properties
- **Credit System**: Dual fungible tokens for biodiversity and carbon credits
- **Verification System**: NGO-based validation using satellite data
- **Trading Marketplace**: Peer-to-peer credit exchange
- **Partnership Management**: NGO authorization and reputation
- **Carbon Integration**: Links habitats to carbon sequestration projects
- **Batch Transfer System**: Efficient multi-recipient credit distribution
- **Credit Retirement System**: Permanent credit retirement for environmental commitment
- **Habitat Upgrade System**: NGO-verified habitat improvements and credit rate adjustments
- **Credit Staking System**: Passive reward mechanism for staked biodiversity credits

### Credit Calculation
**Biodiversity Credits:** `habitat-size-hectares × biodiversity-score`  
**Carbon Credits:** `habitat-size-hectares × carbon-rate-per-hectare`

Credits are minted proportionally based on time elapsed since last minting, with a minimum interval of ~6 months (8760 blocks). Credit swapping available at 75% conversion rate (biodiversity → carbon).

## 🛡️ Security Features

- ✅ Owner-only NGO authorization
- ✅ Verification required before credit minting
- ✅ Balance checks for all transfers
- ✅ Trade status validation
- ✅ Input validation for all parameters
- ✅ Batch transfer validation for total amounts and atomic updates
- ✅ Credit retirement with permanent burning and tracking
- ✅ Staking balance validation and reward calculation integrity

## 🌍 Environmental Impact

Each credit represents verified conservation of biodiversity-rich habitat with optional carbon sequestration benefits. The dual-credit economic incentive structure encourages:
- Long-term habitat preservation
- Carbon sequestration and climate action
- Professional verification standards
- Transparent impact measurement
- Sustainable conservation funding through multiple revenue streams
- Voluntary credit retirement for enhanced environmental commitment
- Staking incentives promoting long-term credit retention and ecosystem stability

## 📊 Data Structures

### Habitat Record
- Owner, location, size, biodiversity score
- Verification status and credits per year
- Last minting block tracking

### NGO Partnership
- Authorization status and verification fees
- Reputation scoring (0-100)

### Trade Orders
- Seller/buyer information
- Credit amount and pricing
- Status tracking (active/completed/cancelled)

### Carbon Projects
- Linked habitat and carbon sequestration rates
- Methodology tracking (VCS, Gold Standard, etc.)
- Active status and minting history

### Retired Credits
- Permanent credit retirement tracking per user
- Burned credits removed from circulation
- Transparency for environmental commitment reporting

### Stake Records
- Staked amount, staking block, and last claim block tracking
- Automatic reward accumulation based on time and amount
- Flexible unstaking with reward auto-claiming

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

---

*Building a sustainable future through blockchain-verified conservation* 🌱
