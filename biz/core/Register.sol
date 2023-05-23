// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Register {
    mapping(bytes32 => mapping(address => address)) _delegations;
    mapping(bytes32 => address[]) _registers;

    function getAllRegisters(bytes32 proposalId) public view returns (address[] memory) {
        return _registers[proposalId];
    }

    function hasRegistered(bytes32 proposalId, address voter) public view returns (bool) {
        return _delegations[proposalId][voter] != address(0x0);
    }

    function getRegister(bytes32 proposalId, address voter) public view returns (address) {
        return _delegations[proposalId][voter];
    }

    function register(bytes32 proposalId, address delegator, address delegatee) public virtual returns (bool) {
        require(!hasRegistered(proposalId, delegator), "Register failed: has registered already");

        _delegations[proposalId][delegator] = delegatee;
        _registers[proposalId].push(delegator);
        return true;
    }
}