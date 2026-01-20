# TreasuryDAO 

## Overview
TreasuryDAO is a minimal, fully on-chain governance system built using OpenZeppelin's Governor framework. It demonstrates a complete governance workflow including proposal creation, voting, timelocked execution, and controlled interaction with a treasury contract. The system uses an ERC20Votes governance token, a Governor contract, a TimelockController, and a governance-controlled treasury.

## Project Context
This project was developed for educational purposes. It's been refined into a clean, self-contained example of real governance architecture suitable for portfolio inclusion.

## Project Structure

### GovToken
- ERC-20 governance token with ERC20Votes and ERC20Permit extensions.
- Voting power tracks token balances.
- Minting is restricted to governance (TimelockController).

### GovGovernor
- Core governance contract responsible for proposal creation, voting, quorum checks, and execution.
- Executes all actions through the Timelock.
- **Integrates**:
    1. GovernorSettings
    2. GovernorCountingSimple
    3. GovernorVotes
    4. GovernorVotesQuorumFraction
    5. GovernorTimelockControl
- **Voting specifics**:
    1. Voting delay: 1 block
    2. Voting period: 50,400 blocks (~1 week)
    3. Quorum: 4% of total voting supply

### TimeLock
- Enforces a minimum execution delay for approved proposals.
- Holds ownership of GovToken and TreasuryDAO.
- Governor is granted proposer role.
- Anyone may execute queued proposals.

### TreasuryDAO
- Governance-controlled ETH treasury.
- Maintains a whitelist of approved recipients.
- All state changes must pass through governance.
- **Governance capabilities**:
    1. Add members
    2. Remove members
    3. Withdraw ETH to whitelisted addresses

## Key Features

### Governance-Controlled Treasury
- TreasuryDAO can receive ETH from any address.
- **Withdrawals require**:
    1. Governance execution
    2. Recipient being whitelisted
    3. Sufficient contract balance

### Whitelist Management
- Governance can add or remove approved recipients.
- Only whitelisted addresses may receive treasury withdrawals.

### Governance Token with Voting Power
- GovToken uses ERC20Votes to track voting power.
- Delegation required before participating in governance.
- Minting is restricted to governance proposals.

### Timelocked Execution
- All successful proposals are queued in the Timelock.
- Execution is delayed by a configurable minimum delay.
- Ensures transparency and prevents instant changes.

## Testing
**Foundry test suite validates**:
    1. Governance restrictions
    2. Whitelisted add and remove behavior
    3. ETH funding
    4. Withdrawal logic
    5. Reverts for unauthorized or invalid actions
    6. Correct simulation of Timelock execution




