// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governor.sol";
import "./setup/Timelock.sol";
import "./setup/Rule.sol";
import "./power/IVotes.sol";
import "./lib/Owner.sol";

contract Dao is Governor {
    string private _name;

    mapping(address => bool) _proposer;

    modifier onlyProposer() {
        if(!_proposer[address(0x0)]) {
            require(_proposer[_msgSender()], "Authority: only proposer");
        }        
        _;
    }

    constructor(string memory gname, Timelock timelockAddress, IVotes tokenAddress, Rule ruleAddress) Governor(timelockAddress, tokenAddress, ruleAddress){
        _name = gname;
        setProposer(_msgSender());
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function setProposer(address account) public virtual onlyOwner() {
        require(!_proposer[account], "Proposer already");
        _proposer[account] = true;
    }

    function removeProposer(address account) public virtual onlyOwner() {
        require(_proposer[account], "None proposer");
        delete _proposer[account];
    }

    function setDelay(uint256 newDelay) public virtual onlyProposer() {
        rule.setDelay(newDelay);
    }

    function setPeriod(uint256 newPeriod) public virtual onlyProposer() {
        rule.setDelay(newPeriod);
    }

    function setQuorum(uint256 newQuorum) public virtual onlyOwner() {
        rule.setDelay(newQuorum);
    }

    function setThreshold(uint256 newThreshold) public virtual onlyOwner() {
        rule.setDelay(newThreshold);
    }

    function getRules(bytes32 proposalId) public view returns (uint256, uint256, uint256, uint256) {
        uint256 delay = rule.getRules(proposalId).delay;
        uint256 period = rule.getRules(proposalId).period;
        uint256 quorum = rule.getRules(proposalId).quorum;
        uint256 threshold = rule.getRules(proposalId).threshold;        
        return (delay, period, quorum, threshold);
    }

    function getTimelock() public view virtual returns (uint256) {
        return timelock.getTimelock();
    }

    function getState(bytes32 proposalId) public view override returns (ProposalState) {
        return super.getState(proposalId);
    }

    function propose(address target, bytes memory data) public virtual returns (bytes32, uint256) {
        return propose(target, data, "");
    }

    function propose(address target, bytes memory data, string memory description) public virtual returns (bytes32, uint256) {
        return propose(target, 0, data, description);
    }

    function propose(address target, uint256 value, bytes memory data, string memory description) public virtual override onlyProposer() returns (bytes32, uint256) {
        return super.propose(target, value, data, description);
    }    

    function getVotes(bytes32 proposalId, address account) public view virtual override returns (uint256) {
        return super.getVotes(proposalId, account);
    }

    function register(bytes32 proposalId, address delegatee) public virtual {
        address delegator = _msgSender();
        register(proposalId, delegator, delegatee);
    }

    function castVote(bytes32 proposalId, uint8 support) public virtual returns (uint256) {
        address voter = _msgSender();
        return castVote(proposalId, voter, support);
    }

    function schedule(bytes32 proposalId) public virtual override {
        super.schedule(proposalId);
    }

    function execute(bytes32 proposalId) public virtual override returns (bool) {
        return super.execute(proposalId);
    }

    function cancel(bytes32 proposalId) public virtual override returns (bool) {
        return super.cancel(proposalId);
    }
}