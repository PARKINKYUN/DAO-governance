// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IVotes {
    function getVotes(bytes32 proposalId, address account) external view returns (uint256);
    function getPastVotes(bytes32 proposalId, address account) external view returns (uint256);
    function setTotalSupply(bytes32 proposalId) external;
    function getTotalSupply(bytes32 proposalId) external view returns (uint256);
    function getRegister(bytes32 proposalId, address account) external view returns (address);
    function register(bytes32 proposalId, address from, address to) external;
    function setToken(IERC20) external;
    function getToken() external view returns (IERC20);
    function getTokenBalance(address proposer) external returns (uint256);
    function setDeadline(bytes32 proposalId, uint256 delay) external;
}