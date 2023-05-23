// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TypeStruct.sol";

contract TypeBiz is TypeStruct {
    struct Proposal {
        address proposer;
        string uri;
        address votingToken;
        bytes32 docHash;
        uint8 votingOptions;
    }
}