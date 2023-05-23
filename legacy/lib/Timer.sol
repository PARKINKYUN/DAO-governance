// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Timer {
    struct Timestamp {
        uint64 _time;
    }

    function getTime(Timestamp memory timer) internal pure returns (uint64) {
        return timer._time;
    }

    function setTime(Timestamp storage timer, uint64 timestamp) internal {
        timer._time = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._time = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._time == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._time > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._time > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._time <= block.timestamp;
    }
}