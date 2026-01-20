// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreasuryDAO is Ownable {
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event FundsReceived(address indexed from, uint256 amount);

    error TreasuryDAO__NotAuthorized();
    error TreasuryDAO__InsufficientContractBalance();
    error TreasuryDAO__TransferFailed();

    mapping(address => bool) private s_whitelist;

    /**
     * @notice Initializes the contract and whitelists the deployer as the first approved member.
     * @dev Ownership will later be transferred to the Timelock, which will execute all governance actions.
     */
    constructor() Ownable(msg.sender) {
        s_whitelist[msg.sender] = true;
    }

    /**
     * @notice Allows the contract to receive ETH.
     * @dev Emits a FundsReceived event for transparency.
     */
    receive() external payable {
        emit FundsReceived(msg.sender, msg.value);
    }

    // --------------------------------
    // Governance-controlled actions
    // --------------------------------

    /**
     * @notice Adds an address to the whitelist of approved recipients.
     * @dev Executed through governance proposals.
     * @param _member The address to be added to the whitelist.
     */
    function addMember(address _member) public onlyOwner {
        s_whitelist[_member] = true;
        emit MemberAdded(_member);
    }

    /**
     * @notice Removes an address from the whitelist of approved recipients.
     * @dev Executed through governance proposals.
     * @param _member The address to be removed from the whitelist.
     */
    function removeMember(address _member) public onlyOwner {
        s_whitelist[_member] = false;
        emit MemberRemoved(_member);
    }

    // --------------------------------
    // Member actions
    // --------------------------------

    /**
     * @notice Withdraws ETH from the treasury to a whitelisted address.
     * @dev The recipient must be whitelisted.
     * @param _to The address receiving the ETH.
     * @param _amount The amount of ETH to withdraw.
     */
    function withdraw(address _to, uint256 _amount) public onlyOwner {
        if (!s_whitelist[_to]) {
            revert TreasuryDAO__NotAuthorized();
        }
        if (address(this).balance < _amount) {
            revert TreasuryDAO__InsufficientContractBalance();
        }

        (bool _success, ) = _to.call{value: _amount}("");

        if (!_success) {
            revert TreasuryDAO__TransferFailed();
        }

        emit FundsWithdrawn(_to, _amount);
    }

    // --------------------------------
    // View functions
    // --------------------------------

    /**
     * @notice Checks whether an address is whitelisted.
     * @param _user The address being queried.
     */
    function isMember(address _user) public view returns (bool) {
        return s_whitelist[_user];
    }

    /**
     * @notice Returns the current ETH balance held by the contract.
     */
    function getBalance() public view returns (uint256 balance) {
        return address(this).balance;
    }
}
