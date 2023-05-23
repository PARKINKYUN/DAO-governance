// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../library/TypeStruct.sol";

contract Rule is TypeStruct {
    uint256 _threshold;
    uint256 _proposalFee;

    mapping(address => Rules) _userRules;
    mapping(bytes32 => Rules) _proposalRules;
    mapping(address => bool) _isInitialized;

    constructor(uint256 threshold, uint256 fee) {
        _setThreshold(threshold);
        _setProposalFee(fee);
    }

    function setThreshold(uint256 threshold) public virtual {
        _setThreshold(threshold);
    }
    function _setThreshold(uint256 threshold) private {
        _threshold = threshold;
    }
    function getThreshold() public view returns (uint256) {
        return _threshold;
    }

    function setProposalFee(uint256 fee) public virtual {
        _setProposalFee(fee);
    }
    function _setProposalFee(uint256 fee) private {
        _proposalFee = fee;
    }
    function getProposalFee() public view returns (uint256) {
        return _proposalFee;
    }

    function setRule(address proposer, uint256 nDelay, uint256 nRgstPeriod, uint256 nVotePeriod, uint256 nSnapTime, uint256 nTimelock, uint256 nTurnout, uint256 nQuorum)
        public virtual returns (bool)
    {
        Rules memory r = Rules(nDelay, nRgstPeriod, nVotePeriod, nSnapTime, nTimelock, nTurnout, nQuorum);
        _userRules[proposer] = r;

        if (!_isInitialized[proposer]) {
            _isInitialized[proposer] = true;
        }
        return true;
    }

    function setRuleByProposal(address proposer, bytes32 proposalId) public virtual {
        require(_isInitialized[proposer], "Rule failed: have to initialize user rules");

        Rules memory r = getRuleByAccount(proposer);
        _proposalRules[proposalId] = r;
    }

    function getRuleByAccount(address account) public view returns (Rules memory) {
        return _userRules[account];
    }

    function getRuleByProposal(bytes32 proposalId) public view returns (Rules memory) {
        return _proposalRules[proposalId];
    }
}