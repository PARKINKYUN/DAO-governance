// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IVotes.sol";
import "./IERC20.sol";
import "../lib/Owner.sol";

contract ERC20Votes is IVotes, Owner {
    IERC20 private token;

    mapping(bytes32 => uint256) private _totalVotes;
    mapping(bytes32 => uint256) private _deadlines;
    mapping(bytes32 => mapping(address => address)) private _registers;
    mapping(bytes32 => mapping(address => uint256)) private _checkpoints;

    constructor(IERC20 _token) {
        token = _token;
    }

    function setToken(IERC20 _token) public virtual onlyOwner() {
        token = _token;
    }

    function getToken() public view virtual returns (IERC20) {
        return token;
    }

    function getTokenBalance(address account) public view virtual returns (uint256) {
        return token.balanceOf(account);
    }

    function setDeadline(bytes32 proposalId, uint256 delay) public virtual onlyOwner() {
        uint256 dl = block.timestamp + delay;
        _deadlines[proposalId] = dl;
    }

    function getVotes(bytes32 proposalId, address account) public view virtual returns (uint256) {
        uint256 cp = _checkpoints[proposalId][account];

        if (_registers[proposalId][account] == address(0x0) && cp == 0) {
            return 0;
        }

        return cp;
    }

    function getPastVotes(bytes32 proposalId, address account) public view virtual returns (uint256) {
        require(_deadlines[proposalId] < block.timestamp, "The proposal is ongoing");
        return _checkpoints[proposalId][account];
    }

    function setTotalSupply(bytes32 proposalId) public virtual onlyOwner() {
        require(_totalVotes[proposalId] == 0, "Invalid proposal ID");
        _setTotalSupply(proposalId);
    }

    function _setTotalSupply(bytes32 proposalId) private {
        uint256 ts = token.totalSupply();
        _totalVotes[proposalId] = ts;
    }

    function getTotalSupply(bytes32 proposalId) public view virtual returns (uint256) {
        return _totalVotes[proposalId];
    }

    function register(bytes32 proposalId, address delegator, address delegatee) public virtual onlyOwner() {
        require(_deadlines[proposalId] > block.timestamp, "The vote is ongoing already");
        _register(proposalId, delegator, delegatee);
    }

    function getRegister(bytes32 proposalId, address account) public view virtual returns (address) {
        return _registers[proposalId][account];
    }

    function _register(bytes32 proposalId, address delegator, address delegatee) private {
        require(delegator != address(0x0) && delegatee != address(0x0), "Invalid address");
        require(_registers[proposalId][delegator] == address(0x0), "No power to delegate");

        _registers[proposalId][delegator] = delegatee;

        uint256 p = getTokenBalance(delegator);
        require(p != 0, "No power to delegate");

        _moveVotingPower(proposalId, delegatee, p);
    }

    function _moveVotingPower(bytes32 proposalId, address account, uint256 amount) private {
        uint256 oldPower = _checkpoints[proposalId][account];
        uint256 newPower = oldPower + amount;

        require(newPower <= type(uint256).max, "The power doesn't fit in 256 bits");

        _checkpoints[proposalId][account] = newPower;
    }
}