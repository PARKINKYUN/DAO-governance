// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Register.sol";
import "./Snap.sol";
import "./Vote.sol";
import "../../setting/Rule.sol";
import "../../library/Authority.sol";

contract Core is Register, Snap, Vote, Rule, Authority {

    constructor(address tokenAddress, uint256 threshold, uint256 fee)
        Vote(tokenAddress)
        Rule(threshold, fee)
        Authority()
    {}

    function setDefaultToken(address newTokenAddress) public override onlyOwner {
        super.setDefaultToken(newTokenAddress);
    }

    function setThreshold(uint256 threshold) public override onlyOwner {
        super.setThreshold(threshold);
    }

    function setProposalFee(uint256 fee) public override onlyOwner {
        super.setProposalFee(fee);
    }

    function setRule(address proposer, uint256 nDelay, uint256 nRgstPeriod, uint256 nVotePeriod, uint256 nSnapTime, uint256 nTimelock, uint256 nTurnout, uint256 nQuorum)
        public override onlyOwner returns (bool)
    {
        bool success = super.setRule(proposer, nDelay, nRgstPeriod, nVotePeriod, nSnapTime, nTimelock, nTurnout, nQuorum);
        return success;
    }

    function setRuleByProposal(address proposer, bytes32 proposalId) public override onlyOwner {
        super.setRuleByProposal(proposer, proposalId);
    }

    function setUsedToken(bytes32 proposalId, address tokenAddress) public override onlyOwner {
        super.setUsedToken(proposalId, tokenAddress);
    }

    function register(bytes32 proposalId, address delegator, address delegatee) public override onlyOwner returns (bool) {
        require(getTokenAmount(proposalId, delegator) > 0, "Core failed: not enough token balance");

        bool success = super.register(proposalId, delegator, delegatee);
        require(success, "Core failed: Can't register voting right");

        return true;
    }

    function castVote(bytes32 proposalId, address voter, uint8 support) public override onlyOwner returns (bool) {
        // Only those who have registered voting-power for themselves can participate in the vote.
        require(voter == getRegister(proposalId, voter), "Core failed: an registered account");

        bool success = super.castVote(proposalId, voter, support);
        return success;
    }

    function snapBefore(bytes32 proposalId) public onlyOwner returns (bool) {
        address[] memory voters = getAllRegisters(proposalId);

        uint256 _totalPower = 0;
        uint256 countVoters = voters.length;
        for( uint256 i = 0 ; i < countVoters ; i++ ){
            address _voter = voters[i];
            uint256 _power = getTokenAmount(proposalId, _voter);
            setSnapBefore(proposalId, _voter, _power);
            _totalPower += _power;
        }

        uint256 _totalSupply = getTotalSupply(proposalId);
        uint256 _registeredTurnout = _totalPower * 100 / _totalSupply;
        uint256 _turnout = getRuleByProposal(proposalId).turnout;
        
        // less than turnout
        if(_registeredTurnout < _turnout){
            return false;
        }

        return true;               
    }

    function snapAfter(bytes32 proposalId) public onlyOwner returns (bool) {
        address[] memory voters = getAllRegisters(proposalId);

        // total turnout
        uint256 _totalTurnout = 0;

        /** @dev
         *  It takes the amount of voting rights from the list and stores the min value in _powerAfter of Snap.sol,
         *  compared to the amount of tokens it currently holds.
         */
        uint256 countVoters = voters.length;
        uint256 maxAccumulatedValue = 0;
        for( uint256 i = 0 ; i < countVoters ; i++ ){
            address _delegator = voters[i];
            address _delegatee = getRegister(proposalId, _delegator);

            // If the delegated account did not participate in the vote
            if(!hasVoted(proposalId, _delegatee)) continue;

            uint256 _curPower = getTokenAmount(proposalId, _delegator);
            uint256 _prePower = getPower(proposalId, _delegator);

            // compare.(min value)
            if(_curPower > _prePower) {
                _curPower = _prePower;
            }

            setSnapAfter(proposalId, _delegator, _curPower);
            _totalTurnout += _curPower;

            // adjustment of voting power
            uint8 _support = getSupport(proposalId, _delegatee);
            uint256 _accumulated = setResult(proposalId, _support, _curPower);

            if(_accumulated > maxAccumulatedValue) {
                maxAccumulatedValue = _accumulated;
            }
        }

        // compare to turnout
        uint256 _totalSupply = getTotalSupply(proposalId);
        uint256 _votingTurnout = _totalTurnout * 100 / _totalSupply;
        uint256 _minTurnout = getRuleByProposal(proposalId).turnout;
        
        if(_votingTurnout < _minTurnout) {
            return false;
        }

        // compare to quorum
        // search a option that satisfies the quorum
        uint256 _maxRate = maxAccumulatedValue * 100 / _totalTurnout;
        uint256 _minQuorum = getRuleByProposal(proposalId).quorum;

        if(_maxRate < _minQuorum) {
            return false;
        }

        return true;
    }
}