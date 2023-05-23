// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./core/Core.sol";
import "../library/Authority.sol";
import "../library/TypeCrypto.sol";
import "../token/IERC20.sol";

contract Governor is Authority, TypeCrypto {
    // contract core module
    Core _core;

    uint256 _nonce = 1;

    mapping(bytes32 => Proposal) _proposals;
    mapping(bytes32 => ProposalStatus) _status;
    mapping(bytes32 => uint256) _nonces;

    constructor(address core) {
        _setCore(Core(core));
    }

    function setCore(Core core) public onlyAdmin {
        _setCore(core);
    }
    function _setCore(Core core) private {
        _core = core;
    }

    function getProposalId(address proposer, address target, bytes memory calldatas, string memory uri, uint256 nonce) public pure returns (bytes32) {
        return keccak256(abi.encode(proposer, target, keccak256(calldatas), keccak256(bytes(uri)), nonce));
    }

    function setRule(address dao, uint256 nDelay, uint256 nRgstPeriod, uint256 nVotePeriod, uint256 nSnapTime, uint256 nTimelock, uint256 nTurnout, uint256 nQuorum) internal {
        // restricted min 60 sec
        require((nRgstPeriod > 60) && (nVotePeriod > 60) && (nSnapTime > 60), "Governor failed: restricted each time for more than 60 seconds");

        _core.setRule(dao, nDelay, nRgstPeriod, nVotePeriod, nSnapTime, nTimelock, nTurnout, nQuorum);
    }

    function getRule() public view returns (Rules memory) {
        return _core.getRuleByAccount(msg.sender);
    }

    function isContract(address _address) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }

    function propose(address proposer, address target, bytes memory calldatas, string memory uri, bytes32 docHash) internal virtual returns (bytes32) {
        require(keccak256(bytes(uri)) != keccak256(bytes("")), "Governor failed: uri is empty");

        // check votingToken contract. address verification!
        require(isContract(target), "Governor failed: target isn't contract address");

        // get proposalId
        bytes32 _proposalId = getProposalId(proposer, target, calldatas, uri, _nonce);

        // check hold amount
        uint256 _threshold = _core.getThreshold();
        uint256 _balance = _core.getDefaultTokenAmount(proposer);
        require(_balance >= _threshold, "Governor failed: token balance is insufficient");

        // check propose-fee
        uint256 _fee = _core.getProposalFee();
        IERC20 _token = _core.getDefaultToken();
        bool success = _token.transferFrom(proposer, address(this), _fee);
        require(success, "Governor failed: proposal-fee must be approved");

        _propose(_proposalId, proposer, target, calldatas, uri, docHash);

        _nonces[_proposalId] = _nonce;
        _nonce++;

        return _proposalId;        
    }

    function _propose(bytes32 proposalId, address proposer, address target, bytes memory calldatas, string memory uri, bytes32 docHash) private {        
        // save vote rules
        _core.setRuleByProposal(address(this), proposalId);

        // save proposal_contents
        _proposals[proposalId] = Proposal(proposer, target, uri, docHash, calldatas);

        // save proposal_status
        Rules memory r = _core.getRuleByProposal(proposalId);

        uint256 _voteRegistration = block.timestamp + r.delay;
        uint256 _voteStart = _voteRegistration + r.registPeriod + r.snapTime;
        uint256 _voteEnd = _voteStart + r.votePeriod;

        _status[proposalId] = ProposalStatus(_voteRegistration, _voteStart, _voteEnd, ProposalState.Pending);

        _core.register(proposalId, proposer, proposer);
    }

    function cancel(bytes32 proposalId, address _proposer) internal {
        Proposal memory p = _proposals[proposalId];
        require(p.proposer == _proposer, "Governor failed: the caller isn't a proposer");

        ProposalState _state = getState(proposalId);
        require(_state == ProposalState.Pending || _state == ProposalState.Registration, "Governor failed: the vote is started already");

        _status[proposalId].state = ProposalState.Canceled;
    }

    function register(bytes32 proposalId, address delegator, address delegatee) internal {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) == ProposalState.Registration, "Governor failed: no registration period");
        
        _core.register(proposalId, delegator, delegatee);
    }

    /** @dev (just using interger but enum)
     * voting options
     * 1 : agree
     * 2 : disagree
     * 3 : abstain
     */
    function castVote(bytes32 proposalId, address voter, uint8 support) internal {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) == ProposalState.Active, "Governor failed: this proposal isn't active");

        _core.castVote(proposalId, voter, support);
    }

    function executeProposal(bytes32 proposalId) internal {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) == ProposalState.Completed, "Governor failed: this proposal isn't completed");

        uint256 _end = _status[proposalId].voteEnd;
        uint256 _lock = _core.getRuleByProposal(proposalId).timelock;
        require(block.timestamp >= _end + _lock, "Governor failed: the waiting time for execution has not passed yet");

        Proposal memory p = _proposals[proposalId];
        (bool success, ) = p.target.call(p.calldatas);
        require(success, "Governor failed: can't execute proposal");

        _status[proposalId].state = ProposalState.Executed;
    }

    function getProposal(bytes32 proposalId) public view returns (Proposal memory) {
        return _proposals[proposalId];
    }

    function getPower(bytes32 proposalId, address voter) public view returns (uint256) {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");

        uint256 _power = _core.getPower(proposalId, voter);
        return _power;
    }

    // All users can't see the voting result when the vote is in progress.
    function getResult(bytes32 proposalId) public view returns (uint256[] memory) {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) != ProposalState.Canceled, "Governor failed: this proposal is canceled");

        uint256 _voteEnd = _status[proposalId].voteEnd;
        require(block.timestamp >= _voteEnd, "Governor failed: can't check voting result yet");

        uint256[] memory v = _core.getResult(proposalId);

        return v;
    }

    function getState(bytes32 proposalId) public view returns (ProposalState) {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");

        uint256 currentTime = block.timestamp;

        ProposalStatus memory ps = _status[proposalId];

        // canceled or succeeded or defeated or executed
        if(
            ps.state == ProposalState.Canceled  ||
            ps.state == ProposalState.Completed ||
            ps.state == ProposalState.Rejected  ||
            ps.state == ProposalState.Executed)
        {
            return ps.state;
        }

        // pending
        if(currentTime < ps.voteRegistration){
            return ProposalState.Pending;
        }

        // registration
        Rules memory r = _core.getRuleByProposal(proposalId);
        if(currentTime < ps.voteRegistration + r.registPeriod){
            return ProposalState.Registration;
        }

        // front snap (using front-snap)
        if(currentTime < ps.voteStart){
            return ProposalState.FrontSnap;
        }

        // voting active
        if(currentTime <= ps.voteEnd && ps.state == ProposalState.FrontSnap){
            return ProposalState.Active;
        }

        // back snap
        if(currentTime > ps.voteEnd && ps.state == ProposalState.FrontSnap){
            return ProposalState.BackSnap;
        }

        // canceled because proposer didn't snap within the period
        return ProposalState.Canceled;
    }

    function snapBeforeVoting(bytes32 proposalId) internal returns (ProposalState) {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) == ProposalState.FrontSnap, "Governor failed: no snap period");

        bool success = _core.snapBefore(proposalId);

        if (success) {
            _status[proposalId].state = ProposalState.FrontSnap;
        } else {
            _status[proposalId].state = ProposalState.Canceled;
        }

        return _status[proposalId].state;
    }

    function snapAfterVoting(bytes32 proposalId) internal returns (ProposalState) {
        require(_nonces[proposalId] != 0, "Governor failed: can't find proposal ID");
        require(getState(proposalId) == ProposalState.BackSnap, "Governor failed: no snap period");

        bool success = _core.snapAfter(proposalId);

        if(success) {
            _status[proposalId].state = ProposalState.Completed;
        } else {
            _status[proposalId].state = ProposalState.Rejected;
        }

        return _status[proposalId].state;
    }
}