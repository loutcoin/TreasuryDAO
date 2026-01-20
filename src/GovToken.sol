// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {TreasuryDAO} from "../src/TreasuryDAO.sol";
import {
    ERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Votes
} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {
    ERC20Permit
} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {GovGovernor} from "../src/GovGovernor.sol";
import {
    Governor
} from "lib/openzeppelin-contracts/contracts/governance/Governor.sol";
import {Nonces} from "lib/openzeppelin-contracts/contracts/utils/Nonces.sol";
import {
    IGovernor
} from "lib/openzeppelin-contracts/contracts/governance/IGovernor.sol";

contract GovToken is ERC20, ERC20Permit, ERC20Votes {
    error GovToken__InvalidAddress();
    error GovToken__NotGovernance();

    /**
     * @notice Deploys the governance token with name "GovToken" and symbol "GTK".
     * @dev
     */
    constructor() ERC20("GovToken", "GTK") ERC20Permit("GovToken") {}

    /**
     * @notice Restricts function access to governance (TimelockController).
     */
    modifier onlyGovernance() {
        if (msg.sender != owner()) revert GovToken__NotGovernance();
        _;
    }

    /**
     * @notice Mints the governance tokens to a specified address.
     * @dev Only callable by governance (Timelock). Ensures token supply changes require proposals.
     * @param to The address receiving the newly minted tokens.
     * @param amount Quantity of tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyGovernance {
        _mint(to, amount);
    }

    /**
     * @notice Internal hook that updates token balances and voting power.
     * @dev Required override for ERC20Votes integration.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param value The amount of tokens transferred.
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /**
     * @notice Internal mint function.
     * @dev Required override for ERC20Votes compatibility.
     * @param to The address receiving the newly minted tokens.
     * @param amount Quantity of tokens to mint.
     */
    function _mint(address to, uint256 amount) internal override(ERC20) {
        super._mint(to, amount);
    }

    /**
     * @notice Internal burn function.
     * @dev Required override for ERC20Votes compatibility.
     * @param account The address whose tokens are being burned.
     * @param amount The number of tokens to burn.
     */
    function _burn(address account, uint256 amount) internal override(ERC20) {
        super._burn(account, amount);
    }

    /**
     * @notice Returns the current nonce for an address used in EIP-2612 signatures
     * @dev Overrides both ERC20Permit and Nonces.
     * @param owner The address whose nonce is being queried.
     */
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
