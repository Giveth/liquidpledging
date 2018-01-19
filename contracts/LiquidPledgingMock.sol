pragma solidity ^0.4.11;
/*
    Copyright 2017, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import "./LiquidPledging.sol";

/// @dev `LiquidPledgingMock` allows for mocking up
///  a `LiquidPledging` contract with the added ability
///  to manipulate the block time for testing purposes.
contract LiquidPledgingMock is LiquidPledging {

    uint public mock_time;

    /// @dev `LiquidPledgingMock` creates a standard `LiquidPledging`
    ///  instance and sets the mocked time to the current blocktime.
    /// @param _vault The vault where ETH backing this pledge is stored    
    function LiquidPledgingMock(
        address _storage,
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) LiquidPledging(_storage, _vault, _escapeHatchCaller, _escapeHatchDestination) public {
        mock_time = now;
    }

    /// @dev `getTime` is a basic getter function for
    ///  the mock_time parameter
    function getTime() internal view returns (uint) {
        return mock_time;
    }

    /// @dev `setMockedTime` is a basic setter function for
    ///  the mock_time parameter
    /// @param _t This is the value to which the mocked time
    ///  will be set.
    function setMockedTime(uint _t) public {
        mock_time = _t;
    }
}
