// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {GovToken} from "../src/GovToken.sol";
import {TreasuryDAO} from "../src/TreasuryDAO.sol";
import {GovGovernor} from "../src/GovGovernor.sol";
import {
    GovernorTimelockControl,
    TimelockController
} from "lib/openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";

contract TimeLock is TimelockController {
    /**
     * @notice Deploys the TimeLockController with a specified delay and role configuration.
     * @dev The deployer is set as initial admin. Proposers and executors define who may queue and execute proposals.
     * @param minDelay The minimum delay (seconds) before a queued proposal may be executed.
     * @param proposers The list of addresses allowed to propose actions to the timelock.
     * @param executors The list of addresses allowed to execute queued proposals.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors
    ) TimelockController(minDelay, proposers, executors, msg.sender) {}
}
