// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Authority {
    address _admin;
    mapping(address => bool) _owners;
    mapping(address => bool) _proposers;

    modifier onlyAdmin() {
        require(_admin == msg.sender, "Owner failed: administrator only");
        _;
    }

    modifier onlyOwner() {
        require(_owners[msg.sender], "Owner failed: owners only");
        _;
    }

    modifier onlyProposer() {
        if(!_proposers[address(0x0)]) {
            require(_proposers[msg.sender], "Owner failed: proposers only");
        }        
        _;
    }

    constructor() {
        _admin = msg.sender;
        _grantOwnership(_admin);
        _setProposer(_admin);
    }

    function isOwner(address account) public view returns (bool) {
        return _owners[account];
    }

    function isProposer(address account) public view returns (bool) {
        return _proposers[account];
    }

    function grantOwner(address newOwner) public onlyAdmin {
        require(newOwner != address(0x0), "Owner failed: This is the zero address");
        _grantOwnership(newOwner);
    }

    function _grantOwnership(address newOwner) private {
        _owners[newOwner] = true;
    }

    function renounceOwner() public onlyOwner {
        delete _owners[msg.sender];
    }

    function revokeOwner(address oldOwner) public onlyAdmin {
        require(_owners[oldOwner], "Owner failed: This address is not the owner");
        delete _owners[oldOwner];
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(_admin != newAdmin, "Owner failed: This address is an admin already");
        _transferAdmin(newAdmin);
    }

    function _transferAdmin(address newAdmin) private {
        _admin = newAdmin;
    }

    function toggleProposer() public onlyOwner returns (bool) {
        if(_proposers[address(0x0)]){
            _proposers[address(0x0)] = false;
            return false;
        }

        _proposers[address(0x0)] = true;
        return true;
    }

    function setProposer(address newProposer) public onlyOwner {
        require(!_proposers[newProposer], "Owner failed: This address is a proposer already");
        _setProposer(newProposer);
    }

    function _setProposer(address newProposer) private {
        _proposers[newProposer] = true;
    }

    function revokeProposer(address oldProposer) public onlyOwner {
        require(_proposers[oldProposer], "Owner failed: This address isn't a proposer");
        delete _proposers[oldProposer];
    }    
}