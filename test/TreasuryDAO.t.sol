// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {GovGovernor} from "../src/GovGovernor.sol";
import {GovToken} from "../src/GovToken.sol";
import {TreasuryDAO} from "../src/TreasuryDAO.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TreasuryDaoTest is Test {
    GovToken govToken;
    GovGovernor govGovernor;
    TreasuryDAO tDao;
    TimeLock timeLock;

    address public USER = makeAddr("user");
    address public RECIPIENT = makeAddr("recipient");

    uint256 public constant INITIAL_SUPPLY = 100 ether;
    uint256 public constant MIN_DELAY = 3600;

    address[] proposers;
    address[] executors;

    function setUp() public {
        // Deploy governance token
        govToken = new GovToken();
        govToken.mint(USER, INITIAL_SUPPLY);

        // Delegate voting
        vm.startPrank(USER);
        govToken.delegate(USER);

        // Deploy timelock
        timeLock = new TimeLock(MIN_DELAY, proposers, executors);

        // Deploy governor
        govGovernor = new GovGovernor(govToken, timeLock);

        // Configure roles
        bytes32 proposerRole = timeLock.PROPOSER_ROLE();
        bytes32 executorRole = timeLock.EXECUTOR_ROLE();
        bytes32 adminRole = timeLock.DEFAULT_ADMIN_ROLE();

        timeLock.grantRole(proposerRole, address(govGovernor));
        timeLock.grantRole(executorRole, address(0));
        timeLock.revokeRole(adminRole, address(USER));
        vm.stopPrank();

        // Deploy TreasuryDAO and transfer ownership to timelock
        tDao = new TreasuryDAO();
        tDao.transferOwnership(address(timeLock));
    }

    // --------------------------------
    // Basic whitelist tests
    // --------------------------------

    function testCannotAddMemberWithoutGovernance() public {
        // onlyOwner (TimeLock) should revert
        vm.expectRevert();
        tDao.addMember(USER);
    }

    function testCannotRemoveMemberWithoutGovernance() public {
        vm.expectRevert();
        tDao.removeMember(USER);
    }

    // --------------------------------
    // ETH funding tests
    // --------------------------------

    function testTreasuryReceivesETH() public {
        vm.deal(USER, 5 ether);
        vm.prank(USER);
        (bool success, ) = address(tDao).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(tDao.getBalance(), 1 ether);
    }

    // --------------------------------
    // Withdraw tests (governance execution simulated)
    // --------------------------------

    function testWithdrawFailsIfInsufficientBalance() public {
        // Whitelisted recipient
        vm.startPrank(address(timeLock));
        tDao.addMember(RECIPIENT);

        vm.expectRevert(
            TreasuryDAO.TreasuryDAO__InsufficientContractBalance.selector
        );
        tDao.withdraw(RECIPIENT, 1 ether);
        vm.stopPrank();
    }

    function testGovernanceCanWithdrawToWhitelistedRecipient() public {
        // Fund TreasuryDAO
        vm.deal(address(tDao), 3 ether);

        // Whitelist recipient
        vm.startPrank(address(timeLock));
        tDao.addMember(RECIPIENT);

        // Execute withdrawal
        tDao.withdraw(RECIPIENT, 1 ether);
        vm.stopPrank();

        assertEq(RECIPIENT.balance, 1 ether);
        assertEq(tDao.getBalance(), 2 ether);
    }

    // --------------------------------
    // Whitelist view test
    // --------------------------------

    function testIsMemberReturnsCorrectValue() public {
        assertFalse(tDao.isMember(RECIPIENT));

        vm.startPrank(address(timeLock));
        tDao.addMember(RECIPIENT);
        vm.stopPrank();

        assertTrue(tDao.isMember(RECIPIENT));
    }
}
