// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Owner.sol";

contract Rule is Owner {
    uint256 private _delay;
    uint256 private _period;
    uint256 private _quorum;
    uint256 private _threshold;
    
    uint256 private _feeToPropose;
    
    struct Condition {
        uint256 delay;
        uint256 period;
        uint256 quorum;
        uint256 threshold;
    }

    mapping(bytes32 => Condition) rules;

    constructor(uint256 delay_, uint256 period_, uint256 quorum_, uint256 threshold_, uint256 fee_) Owner() {
        _setConfig(delay_, period_, quorum_, threshold_, fee_);
    }    

    function _setConfig(uint256 delay_, uint256 period_, uint256 quorum_, uint256 threshold_, uint256 fee_) private {
        require(quorum_ <= 100, "Out of range");

        _delay = delay_;
        _period = period_;
        _quorum = quorum_;
        _threshold = threshold_;

        _feeToPropose = fee_;
    }

    function setDelay(uint256 newDelay) public virtual onlyOwner() {
        _delay = newDelay;
    }

    function getDelay() public view virtual returns (uint256) {
        return _delay;
    }

    function setPeriod(uint256 newPeriod) public virtual onlyOwner() {
        _period = newPeriod;
    }

    function getPeriod() public view virtual returns (uint256) {
        return _period;
    }

    function setQuorum(uint256 newQuorum) public virtual onlyAdmin() {
        _quorum = newQuorum;
    }

    function getQuorum() public view virtual returns (uint256) {
        return _quorum;
    }

    function setThreshold(uint256 newThreshold) public virtual onlyAdmin() {
        _threshold = newThreshold;
    }

    function getThreshold() public view virtual returns (uint256) {
        return _threshold;
    }

    function setFeeToPropose(uint256 newFee) public virtual onlyAdmin() {
        _feeToPropose = newFee;
    }

    function getFeeToPropose() public view virtual returns (uint256) {
        return _feeToPropose;
    }

    // save proposal-rule
    function saveRules(bytes32 _proposalId) public virtual onlyOwner() {
        Condition memory rule = Condition(_delay, _period, _quorum, _threshold);
        rules[_proposalId] = rule;
    }

    function getRules(bytes32 _proposalId) public view virtual returns (Condition memory) {
        return rules[_proposalId];
    }

    function getQuorumByProposal(bytes32 _proposalId) public view virtual returns (uint256) {
        return rules[_proposalId].quorum;
    }
}