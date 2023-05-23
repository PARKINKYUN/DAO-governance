// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../token/IERC20.sol";

contract Vote {
    IERC20 _origin;

    mapping(bytes32 => mapping(uint8 => uint256)) _result;
    mapping(bytes32 => mapping(address => uint8)) _supports;
    mapping(bytes32 => address) _usedToken;
    
    constructor(address tokenAddress){
        _setDefaultToken(IERC20(tokenAddress));
    }

    function setDefaultToken(address newToken) public virtual {
        require(newToken != address(0x0), "Vote failed: This is zero address");
        _setDefaultToken(IERC20(newToken));
    }

    function _setDefaultToken(IERC20 newToken) private {
        _origin = newToken;
    }

    function getDefaultToken() public view returns (IERC20) {
        return _origin;
    }

    function getDefaultTokenAmount(address account) public view returns (uint256) {
        return _origin.balanceOf(account);
    }

    function getUsedToken(bytes32 proposalId) public view returns (address) {
        return _usedToken[proposalId];
    }

    function getTotalSupply(bytes32 proposalId) public view returns (uint256) {
        return IERC20(_usedToken[proposalId]).totalSupply();
    }

    function getTokenAmount(bytes32 proposalId, address account) public view returns (uint256) {
        return IERC20(_usedToken[proposalId]).balanceOf(account);
    }

    function setUsedToken(bytes32 proposalId, address tokenAddress) public virtual {
        _usedToken[proposalId] = tokenAddress;
    }

    function hasVoted(bytes32 proposalId, address voter) public view returns (bool) {
        return _supports[proposalId][voter] != 0;
    }

    function castVote(bytes32 proposalId, address voter, uint8 support) public virtual returns (bool) {
        require(!hasVoted(proposalId, voter), "Vote failed: has voted already");

        _supports[proposalId][voter] = support;
     
        return true;
    }

    function getSupport(bytes32 proposalId, address voter) public view returns (uint8) {
        require(_supports[proposalId][voter] != 0, "Vote failed: has not voted yet");

        return _supports[proposalId][voter];
    }

    function setResult(bytes32 proposalId, uint8 support, uint256 power) internal returns (uint256) {
        _result[proposalId][support] += power;
        return _result[proposalId][support];
    }

    function getResult(bytes32 proposalId, uint8 support) public view returns (uint256[] memory) {
        uint256[] memory v = new uint256[](support + 1);

        // The data of index '0' is dummy
        for(uint8 i = 1 ; i <= support ; i++ ){
            v[i] = _result[proposalId][i];
        }

        return v;
    }
}