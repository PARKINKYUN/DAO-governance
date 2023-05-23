// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governor.sol";

contract Dao is Governor {
    string private _name;

    event Propose(bytes32 indexed proposalId, address indexed proposer, string indexed uri);

    constructor(string memory gname, address core) Governor(core) {
        _name = gname;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function setRule(uint256 delay, uint256 rgstPeriod, uint256 votePeriod, uint256 snapTime, uint256 timelock, uint256 turnout, uint256 quorum) public onlyProposer {
        setRule(msg.sender, delay, rgstPeriod, votePeriod, snapTime, timelock, turnout, quorum);
    }

    // overloading for four-cases
    function propose(string memory uri, uint8 votingOptions) public onlyProposer returns (bytes32) {
        address _originToken = address(_core.getDefaultToken());

        bytes32 _proposalId = propose(uri, votingOptions, _originToken, keccak256(bytes("")));
        return _proposalId;
    }
    function propose(string memory uri, uint8 votingOptions, bytes32 docHash) public onlyProposer returns (bytes32) {
        address _originToken = address(_core.getDefaultToken());

        bytes32 _proposalId = propose(uri, votingOptions, _originToken, docHash);
        return _proposalId;
    }
    function propose(string memory uri, uint8 votingOptions, address votingToken) public onlyProposer returns (bytes32) {
        bytes32 _proposalId = propose(uri, votingOptions, votingToken, keccak256(bytes("")));
        return _proposalId;
    }
    function propose(string memory uri, uint8 votingOptions, address votingToken, bytes32 docHash) public onlyProposer returns (bytes32) {
        bytes32 _proposalId = propose(msg.sender, uri, votingOptions, votingToken, docHash);

        emit Propose(_proposalId, msg.sender, uri);
        return _proposalId;
    }

    function cancel(bytes32 proposalId) public onlyProposer returns (bool) {
        bool success = cancel(proposalId, msg.sender);
        require(success, "Dao failed: Can't cancel this proposal");
        
        return true;
    }

    function register(bytes32 proposalId, address delegatee) public returns (bool) {
        bool success = register(proposalId, msg.sender, delegatee);
        return success;
    }

    function snapBefore(bytes32 proposalId) public returns (bool) {
        ProposalState ps = snapBeforeVoting(proposalId);

        if(ps == ProposalState.Canceled) {
            return false;
        }

        return true;
    }

    function castVote(bytes32 proposalId, uint8 support) public returns (bool) {
        bool success = castVote(proposalId, msg.sender, support);
        return success;
    }

    function snapAfter(bytes32 proposalId) public returns (bool) {
        ProposalState ps = snapAfterVoting(proposalId);

        if(ps == ProposalState.Rejected) {
            return false;
        }

        return true;
    }

    function execute(bytes32 proposalId) public returns (bool) {
        bool success = executeProposal(proposalId);
        return success;
    }
}