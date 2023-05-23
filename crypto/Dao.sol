// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governor.sol";

contract Dao is Governor {
    string private _name;

    event Propose(bytes32 indexed proposalId, address indexed proposer, bytes32 docHash);

    constructor(string memory gname, address core) Governor(core) {
        _name = gname;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function setRule(uint256 delay, uint256 rgstPeriod, uint256 votePeriod, uint256 snapTime, uint256 timelock, uint256 turnout, uint256 quorum) public onlyOwner {
        setRule(address(this), delay, rgstPeriod, votePeriod, snapTime, timelock, turnout, quorum);
    }

    function propose(address target, bytes memory calldatas, string memory uri) public onlyProposer() returns (bytes32) {
        bytes32 proposalId = propose(target, calldatas, uri, keccak256(bytes("")));
        return proposalId;   
    }
    function propose(address target, bytes memory calldatas, string memory uri, bytes32 docHash) public onlyProposer() returns (bytes32) {
        bytes32 proposalId = propose(msg.sender, target, calldatas, uri, docHash);

        emit Propose(proposalId, msg.sender, docHash);
        return proposalId;
    }

    function cancel(bytes32 proposalId) public onlyProposer returns (bool) {
        cancel(proposalId, msg.sender);
        return true;
    }

    function register(bytes32 proposalId, address delegatee) public returns (bool) {
        register(proposalId, msg.sender, delegatee);
        return true;
    }

    function snapBefore(bytes32 proposalId) public returns (bool) {
        ProposalState ps = snapBeforeVoting(proposalId);

        if(ps == ProposalState.Canceled) {
            return false;
        }

        return true;
    }

    function castVote(bytes32 proposalId, uint8 support) public returns (bool) {
        castVote(proposalId, msg.sender, support);
        return true;
    }

    function snapAfter(bytes32 proposalId) public returns (bool) {
        ProposalState ps = snapAfterVoting(proposalId);

        if(ps == ProposalState.Rejected) {
            return false;
        }

        return true;
    }

    function execute(bytes32 proposalId) public returns (bool) {
        executeProposal(proposalId);
        return true;
    }
}