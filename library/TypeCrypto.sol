// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TypeStruct.sol";

contract TypeCrypto is TypeStruct {
    struct Proposal {
        address proposer;
        address target;
        string uri;
        bytes32 docHash;
        bytes calldatas;
    }
}