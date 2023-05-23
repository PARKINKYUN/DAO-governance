// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Owner {
    mapping(address => bool) _owners;
    address _admin;

    constructor() {
        _admin = _msgSender();
        _addOwnership(_admin);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier onlyAdmin() {
        _checkAdmin();
        _;
    }

    function admin() public view virtual returns (address) {
        return _admin;
    }

    function _checkAdmin() internal view virtual {
        require(admin() == _msgSender(), "The caller is not the admin");
    }

    function transferAdmin(address newAdmin) public virtual onlyAdmin {
        require(newAdmin != address(0), "The new admin is the zero address");
        _transferAdmin(newAdmin);
    }

    function _transferAdmin(address newAdmin) private {
        _admin = newAdmin;
    }

    function _checkOwner() internal view virtual {
        require(_owners[_msgSender()], "The caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        delete _owners[_msgSender()];
    }

    function addOwnership(address newOwner) public virtual onlyAdmin {
        require(newOwner != address(0), "The new owner is the zero address");
        _addOwnership(newOwner);
    }

    function _addOwnership(address newOwner) private {
        require(!_owners[newOwner], "Owner already");
        _owners[newOwner] = true;
    }

    function removeOwnership(address oldOwner) public virtual onlyAdmin {
        require(_owners[oldOwner], "The address is not the owner");
        delete _owners[oldOwner];
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}