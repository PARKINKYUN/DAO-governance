// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/Owner.sol";

contract Timelock is Owner {
    uint256 private _timelock;

    mapping(bytes32 => uint256) private _timelocks;
    mapping(bytes32 => uint256) private _nonces;

    constructor(uint256 timelock_) Owner() {
        _timelock = timelock_;
    }

    function getIdByProposal(address target, uint256 value, bytes memory data, bytes32 descriptionHash, uint256 nonce) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, descriptionHash, nonce));
    }

    // 상태 구분 없이 timelock 에 있는 오퍼레이션인지 여부
    function isOperation(bytes32 proposalId) public view virtual returns (bool registered) {
        return getTimestamp(proposalId) > 0;
    }

    // timelock 기간 대기 중인 오퍼레이션인지 여부
    function isOperationPending(bytes32 proposalId) public view virtual returns (bool pending) {
        uint256 _time = getTimestamp(proposalId);
        return _time > 0 && _time > block.timestamp;
    }

    // timelock 기간이 지나 실행 가능한 오퍼레이션인지 여부
    function isOperationReady(bytes32 proposalId) public view virtual returns (bool ready) {
        uint256 _time = getTimestamp(proposalId);
        return _time > 0 && _time < block.timestamp;
    }

    // 실행 완료된 오퍼레이션인지 여부
    function isOperationDone(bytes32 proposalId) public view virtual returns (bool done) {
        return getTimestamp(proposalId) == 1;
    }

    function getTimestamp(bytes32 proposalId) public view virtual returns (uint256 timestamp) {
        return _timelocks[proposalId];
    }

    function getTimelock() public view virtual returns (uint256 duration) {
        return _timelock;
    }

    function schedule(bytes32 proposalId, uint256 nonce) public virtual onlyOwner() {
        require(!isOperation(proposalId), "Timelock: operation already scheduled");
        _schedule(proposalId, nonce);
    }

    function _schedule(bytes32 proposalId, uint256 nonce) private {
        _timelocks[proposalId] = block.timestamp + getTimelock();
        _nonces[proposalId] = nonce;
    }

    function cancel(bytes32 proposalId) public virtual onlyOwner() {
        require(isOperationPending(proposalId), "Timelock: operation cannot be cancelled");
        delete _timelocks[proposalId];
        delete _nonces[proposalId];
    }

    function execute(address target, uint256 value, bytes memory data, bytes32 descriptionHash, uint256 nonce) public virtual onlyOwner() returns (bool) {
        bytes32 _id = getIdByProposal(target, value, data, descriptionHash, nonce);
        require(isOperationReady(_id), "Timelock: operation is not ready");
        require(_getNonce(_id) == nonce, "Invalid proposal contents");

        _timelocks[_id] = 1;
        return true;
    }

    function _getNonce(bytes32 proposalId) internal view virtual returns (uint256) {
        return _nonces[proposalId];
    }

    function _afterCall(bytes32 proposalId) private {
        _timelocks[proposalId] = 1;
    }

    function setTimelock(uint256 newTimelock) external virtual onlyOwner() {
        _timelock = newTimelock;
    }
}