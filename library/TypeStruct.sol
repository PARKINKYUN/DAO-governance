// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TypeStruct {
    struct ProposalStatus {
        uint256 voteRegistration;
        uint256 voteStart;
        uint256 voteEnd;
        ProposalState state;
    }

    enum ProposalState {
        Pending,
        Registration,
        FrontSnap,
        Canceled,
        Active,
        BackSnap,
        Completed,
        Rejected,
        Executed
    }

    struct Rules {
        // timestamp units
        uint256 delay;
        uint256 registPeriod;
        uint256 votePeriod;
        uint256 snapTime;
        uint256 timelock;
        // percent units
        uint256 turnout;
        uint256 quorum;
    }
}