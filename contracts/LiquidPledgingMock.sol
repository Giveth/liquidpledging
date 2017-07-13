pragma solidity ^0.4.11;

import "./LiquidPledging.sol";

// @dev LiquidPledgingMock mocks current block number

contract LiquidPledgingMock is LiquidPledging {

    uint mock_time;

    function LiquidPledgingMock(address _vault) LiquidPledging(_vault) {
        mock_time = now;
    }

    function getTime() internal returns (uint) {
        return mock_time;
    }

    function setMockedTime(uint _t) {
        mock_time = _t;
    }
}
