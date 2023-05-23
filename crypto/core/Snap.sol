// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Snap {
    mapping(bytes32 => mapping(address => uint256)) _powerBefore;
    mapping(bytes32 => mapping(address => uint256)) _powerAfter;

    function setSnapBefore(bytes32 proposalId, address voter, uint256 power) internal {
        _powerBefore[proposalId][voter] = power;
    }

    function setSnapAfter(bytes32 proposalId, address voter, uint256 power) internal {
        _powerAfter[proposalId][voter] = power;
    }

    function getPower(bytes32 proposalId, address voter) public view returns (uint256) {
        if(_powerAfter[proposalId][voter] != 0){
            return _powerAfter[proposalId][voter];
        }
        return _powerBefore[proposalId][voter];
    }
}