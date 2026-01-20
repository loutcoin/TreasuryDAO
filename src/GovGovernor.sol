// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    Governor
} from "lib/openzeppelin-contracts/contracts/governance/Governor.sol";
import {
    GovernorSettings
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import {
    GovernorCountingSimple
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import {
    GovernorVotes
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import {
    GovernorVotesQuorumFraction
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {
    GovernorTimelockControl
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";
import {GovToken} from "../src/GovToken.sol";
import {TreasuryDAO} from "../src/TreasuryDAO.sol";
import {
    TimelockController
} from "lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";
import {
    IGovernor
} from "lib/openzeppelin-contracts/contracts/governance/IGovernor.sol";
import {
    IVotes
} from "lib/openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

contract GovGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    /**
     * @notice Initializes the Governor with voting token, timelock, voting delay, voting period, and quorum settings.
     * @dev The Governor name is set to "TreasuryGovernor". Voting delay is 1 block, voting period is 50,400 blocks (~1 week),
     * and quorum is set to 4% of total voting power.
     * @param _token The ERC20Votes-compatible token used for voting power.
     * @param _timelock The TimelockController that will execute approved proposals.
     */
    constructor(
        IVotes _token,
        TimelockController _timelock
    )
        Governor("TreasuryGovernor")
        GovernorSettings(1, /* 1 block */ 50400, /* 1 week */ 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    /**
     * @notice Returns the number of blocks voters must wait after a proposal is submitted before voting begins.
     * @dev Overrides required by Solidity due to multiple inheritance.
     */
    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    /**
     * @notice Returns the duration of the voting period in blocks.
     * @dev Overrides required by Solidity due to multiple inheritance.
     */
    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    /**
     * @notice Returns the quorum required for a proposal to pass at a given block number.
     * @dev Uses a quorum fraction of total voting supply.
     * @param blockNumber The block number at which quorum is calculated.
     */
    function quorum(
        uint256 blockNumber
    )
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    /**
     * @notice Returns the current state of a proposal.
     * @dev Integrates GovernorTimelockControl state transitions.
     * @param proposalId The ID of the proposal.
     */
    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    /**
     * @notice Creates a new governance proposal.
     * @dev Proposals include target addresses, ETH values, calldata payloads, and a readable description.
     * @param targets The list of contract addresses to be called.
     * @param values The ETH values to send with each call.
     * @param calldatas The encoded function calls to execute.
     * @param description Readable description of the proposal.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @notice Returns the minimum voting power required to create a proposal.
     * @dev In this implementation, the threshold is zero.
     */
    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    /**
     * @notice Indicates whether a proposal must be queued in the timelock before execution.
     * @dev Returns false if the proposal is already queued. Returns true otherwise.
     */
    function proposalNeedsQueuing(
        uint256
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        uint256 proposalId;
        ProposalState proposalState = super.state(proposalId);
        if (proposalState == ProposalState.Queued) {
            return false;
        } else {
            return true;
        }
    }

    /**
     * @notice Executes a proposal after it has passed and been queued in the timelock.
     * @dev Calls the underlying Governor execution logic.
     * @param targets The list of contract addresses to be called.
     * @param values The ETH values to send with each call.
     * @param calldatas The encoded function calls to execute.
     * @param descriptionHash The keccak256 hash of the proposal description.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable override(Governor) returns (uint256) {
        uint256 proposalId = super.execute(
            targets,
            values,
            calldatas,
            descriptionHash
        );
        return proposalId;
    }

    /**
     * @notice Internal function that executes queued proposal operations.
     * @dev Integrates GovernorTimelockControl execution flow.
     * @param proposalId The ID of the proposal being executed.
     * @param targets The list of contract addresses to be called.
     * @param values The ETH values to send with each call.
     * @param calldatas The encoded function calls to execute.
     * @param descriptionHash The keccak256 hash of the proposal description.
     */
    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    /**
     * @notice Internal function that cancels a proposal.
     * @dev Integrates GovernorTimelockControl cancellation flow.
     * @param targets The list of contract addresses associated with the proposal.
     * @param values The ETH values associated with the proposal.
     * @param calldatas The encoded function calls associated with the proposal.
     * @param descriptionHash The keccak256 hash of the proposal description.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    /**
     * @notice Returns the executor address responsible for executing proposals.
     * @dev In this implementation, the executor is TimelockController.
     */
    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    /**
     * @notice Indicates whether the contract supports a given interface.
     * @dev Required override for Governor compatibility.
     * @param interfaceId The interface identifier.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(Governor) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Internal function that queues proposal operations in the timelock.
     * @dev This implementation returns 0 because queuing is handled by GovernorTimelockControl.
     */
    function _queueOperations(
        uint256 /*proposalId*/,
        address[] memory /*targets*/,
        uint256[] memory /*values*/,
        bytes[] memory /*calldatas*/,
        bytes32 /*descriptionHash*/
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return 0;
    }
}
