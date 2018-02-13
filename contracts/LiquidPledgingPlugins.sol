pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
                  Arthur Lunn

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

import "@aragon/os/contracts/apps/AragonApp.sol";
import "./LiquidPledgingStorage.sol";

/// NOTICE: This contract is not using EternalStorage. This is done to save gas. The pluginWhitelist
/// should be fairly small, and would be trivial and relatively cheap to re-add all valid plugins
/// when the LiquidPledging contract is upgraded
contract LiquidPledgingPlugins is LiquidPledgingStorage, AragonApp {

    bytes32 constant public PLUGIN_MANAGER_ROLE = keccak256("PLUGIN_MANAGER_ROLE");

    function addValidPlugin(bytes32 contractHash) auth(PLUGIN_MANAGER_ROLE) public {
        pluginWhitelist[contractHash] = true;
    }

    function addValidPlugins(bytes32[] contractHashes) external auth(PLUGIN_MANAGER_ROLE) {
        for (uint8 i = 0; i < contractHashes.length; i++) {
            addValidPlugin(contractHashes[i]);
        }
    }

    function removeValidPlugin(bytes32 contractHash) external auth(PLUGIN_MANAGER_ROLE) {
        pluginWhitelist[contractHash] = false;
    }

    function useWhitelist(bool useWhitelist) external auth(PLUGIN_MANAGER_ROLE) {
        whitelistDisabled = !useWhitelist;
    }

    function isValidPlugin(address addr) public view returns(bool) {
        if (whitelistDisabled || addr == 0x0) {
            return true;
        }

        bytes32 contractHash = getCodeHash(addr);

        return pluginWhitelist[contractHash];
    }

    function getCodeHash(address addr) public view returns(bytes32) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}