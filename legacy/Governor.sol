// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./setup/Timelock.sol";
import "./setup/Rule.sol";
import "./power/IVotes.sol";
import "./power/IERC20.sol";
import "./lib/Timer.sol";
import "./lib/Owner.sol";

contract Governor is Owner {
    IVotes internal token;
    Timelock internal timelock;
    Rule internal rule;

    using Timer for Timer.Timestamp;

    struct Proposal {
        address proposer;
        address target;
        uint256 value;
        bytes32 descriptionHash;
        bytes callData;
    }

    struct ProposalStatus {
        Timer.Timestamp voteStart;
        Timer.Timestamp voteEnd;
        uint256 forVote;
        uint256 againstVote;
        uint256 abstainVote;
        ProposalState state;
    }

    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Ready,
        Executed
    }

    enum VoteType {
        For,
        Against,
        Abstain
    }

    // proposalId 의 고유성을 위한 변수
    uint256 private _nonce = 1;
    mapping(bytes32 => uint256) private _nonces;

    mapping(bytes32 => Proposal) private _proposals;
    mapping(bytes32 => ProposalStatus) private _status;
    mapping(bytes32 => mapping(address => bool)) private _voted;

    event Propose(bytes32 indexed proposalId, address indexed proposer, uint256 indexed nonce);

    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "only Governance");
        _;
    }

    constructor(Timelock timelockAddress, IVotes tokenAddress, Rule ruleAddress) Owner() {
        _setToken(tokenAddress);
        _setTimelock(timelockAddress); 
        _setRule(ruleAddress);
    }

    function setTimelock(Timelock newTimelock) public virtual onlyGovernance {
        _setTimelock(newTimelock);
    }

    function _setTimelock(Timelock newTimelock) private {
        timelock = newTimelock;
    }

    function setToken(IVotes newToken) public virtual onlyGovernance {
        _setToken(newToken);
    }

    function _setToken(IVotes newToken) private {
        token = newToken;
    }

    function setRule(Rule newRule) public virtual onlyGovernance {
        _setRule(newRule);
    }

    function _setRule(Rule newRule) private {
        rule = newRule;
    }

    function getIdByProposal(address target, uint256 value, bytes memory data, string memory description, uint256 nonce) public pure virtual returns (bytes32) {
        bytes32 hash = getDescriptionHash(description);
        return keccak256(abi.encode(target, value, data, hash, nonce));
    }

    function getDescriptionHash(string memory description) public pure returns (bytes32) {
        return keccak256(bytes(description));
    }

    function getState(bytes32 proposalId) public view virtual returns (ProposalState) {
        require(_nonces[proposalId] > 0, "Unknown proposal id");

        ProposalState st = _status[proposalId].state;

        if (st == ProposalState.Executed || st == ProposalState.Canceled) {
            return st;
        }

        uint256 startTime = proposalStart(proposalId);

        if (startTime >= block.timestamp) {
            return ProposalState.Pending;
        }

        uint256 endTime = proposalEnd(proposalId);

        if (endTime >= block.timestamp) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId)) {
            // success
            if(timelock.isOperationDone(proposalId)) {
                return ProposalState.Executed;
            } else if (timelock.isOperationPending(proposalId)) {
                return ProposalState.Queued;
            } else if (timelock.isOperationReady(proposalId)) {
                return ProposalState.Ready;
            } else {
                return ProposalState.Succeeded;
            }
        } else {
            return ProposalState.Defeated;
        }
    }

    function proposalStart(bytes32 proposalId) public view virtual returns (uint256) {
        return _status[proposalId].voteStart.getTime();
    }

    function proposalEnd(bytes32 proposalId) public view virtual returns (uint256) {
        return _status[proposalId].voteEnd.getTime();
    }

    function _quorumReached(bytes32 proposalId) internal view virtual returns (bool) {
        return quorum(proposalId) <= _status[proposalId].forVote;
    }

    function quorum(bytes32 proposalId) public view virtual returns (uint256) {
        return (token.getTotalSupply(proposalId) * rule.getQuorumByProposal(proposalId)) / 100;
    }

    function hasVoted(bytes32 proposalId, address account) public view virtual returns (bool) {
        return _voted[proposalId][account];
    }

    function countVotes(bytes32 proposalId) public view virtual returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
        ProposalStatus memory status = _status[proposalId];
        return (status.forVote, status.againstVote, status.abstainVote);
    }

    function propose(address target, uint256 value, bytes memory data, string memory description) public virtual returns (bytes32, uint256) {
        // check authority
        address _proposer = _msgSender();

        // check hold amount
        uint256 _threshold = rule.getThreshold();
        uint256 _proposerPower = token.getTokenBalance(_proposer);
        require(_proposerPower >= _threshold, "Not enough vote power");

        // check propose-fee
        IERC20 originToken = token.getToken();
        uint256 _pFee = rule.getFeeToPropose();

        bool success = originToken.transferFrom(_proposer, address(this), _pFee);
        require(success, "No token approved");

        // get propose ID
        bytes32 proposalId = getIdByProposal(target, value, data, description, _nonce);
        require(_nonces[proposalId] == 0, "Governor: proposal already exists");

        // save vote rules
        rule.saveRules(proposalId);

        // save proposal-content
        Proposal storage p = _proposals[proposalId];
        p.proposer = _msgSender();
        p.target = target;
        p.callData = data;
        p.descriptionHash = getDescriptionHash(description);

        // save proposal-status
        ProposalStatus storage status = _status[proposalId];
        require(status.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 startTime = uint64(block.timestamp + rule.getRules(proposalId).delay);
        uint64 endTime = startTime + uint64(rule.getRules(proposalId).period);

        status.voteStart.setTime(startTime);
        status.voteEnd.setTime(endTime);
        status.state = ProposalState.Pending;

        _nonces[proposalId] = _nonce;

        // save a snapshot of 'total & proposer'
        token.setTotalSupply(proposalId);

        uint256 _delay = rule.getDelay();
        token.setDeadline(proposalId, _delay);
        _register(proposalId, _proposer, _proposer);

        emit Propose(proposalId, _proposer, _nonce);

        // nonce를 1 증가시킨다.
        _nonce++;

        return (proposalId, _nonces[proposalId]);
    }

    function getProposal(bytes32 proposalId) public view virtual returns (Proposal memory) {
        require(_nonces[proposalId] != 0, "Invalid proposal");
        return _proposals[proposalId];
    }

    function register(bytes32 proposalId, address delegator, address delegatee) internal virtual {
        return _register(proposalId, delegator, delegatee);
    }

    function _register(bytes32 proposalId, address delegator, address delegatee) private {
        return token.register(proposalId, delegator, delegatee);
    }

    function getVotes(bytes32 proposalId, address account) public view virtual returns (uint256) {
        return token.getVotes(proposalId, account);
    }

    function castVote(bytes32 proposalId, address account, uint8 support) internal virtual returns (uint256) {
        require(_nonces[proposalId] != 0, "Governor: invalid proposal ID");
        return _castVote(proposalId, account, support);
    }

    function _castVote(bytes32 proposalId, address account, uint8 support) private returns (uint256) {
        require(getState(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 _power = getVotes(proposalId, account);
        require(_power != 0 || !_voted[proposalId][account], "Governor: Can't vote");

        ProposalStatus storage ps = _status[proposalId];

        if(support == uint8(VoteType.For)) {
            ps.forVote = ps.forVote + _power;
        } else if(support == uint8(VoteType.Against)) {
            ps.againstVote = ps.againstVote + _power;
        } else if(support == uint8(VoteType.Abstain)) {
            ps.abstainVote = ps.abstainVote + _power;
        } else {
            revert("Governor: Invalid support type");
        }

        _voted[proposalId][account] = true;

        return _power;
    }

    function schedule(bytes32 proposalId) public virtual {
        require(getState(proposalId) == ProposalState.Succeeded, "Invalid proposal");

        uint nonce = _nonces[proposalId];
        timelock.schedule(proposalId, nonce);
    }

    function execute(bytes32 proposalId) public virtual returns (bool) {
        require(getState(proposalId) == ProposalState.Ready, "Timelock: proposal is pending yet or rejected");

        Proposal memory p = _proposals[proposalId];
        address target = p.target;
        uint256 value = p.value;
        bytes memory callData = p.callData;
        bytes32 descriptionHash = p.descriptionHash;
        uint nonce = _nonces[proposalId];

        bool success = timelock.execute(target, value, callData, descriptionHash, nonce);

        if(!success) {
            revert("Governor: call reverted");
        }

        _beforeExecute(proposalId, target, value, callData, descriptionHash);

        bytes memory data = abi.encode(callData);

        (success, data) = target.call{value: value}(data);
        if(!success) {
            revert(string(data));
        }

        _status[proposalId].state = ProposalState.Executed;

        _afterExecute(proposalId, target, value, callData, descriptionHash);

        return true;
    }

    function getProposer(bytes32 proposalId) public view virtual returns (address) {
        return _proposals[proposalId].proposer;
    }

    function cancel(bytes32 proposalId) public virtual returns (bool) {
        require(proposalStart(proposalId) > block.timestamp, "Governot: vote cannot be cancelled");

        _cancel(proposalId);
        return true;
    }

    function _cancel(bytes32 proposalId) private {
        timelock.cancel(proposalId);

        delete _proposals[proposalId];
        delete _status[proposalId];
    }

    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    // hooks
    function _beforeExecute(bytes32 proposalId, address target, uint256 value, bytes memory calldatas, bytes32 descriptionHash) internal virtual {
    }

    function _afterExecute(bytes32 proposalId, address target, uint256 value, bytes memory calldatas, bytes32 descriptionHash) internal virtual {
    }
}