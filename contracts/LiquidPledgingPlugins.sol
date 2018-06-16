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
import "./LiquidPledgingACLHelpers.sol";

contract LiquidPledgingPlugins is AragonApp, LiquidPledgingStorage, LiquidPledgingACLHelpers {

    bytes32 constant public PLUGIN_MANAGER_ROLE = keccak256("PLUGIN_MANAGER_ROLE");

    /**
    * @dev adds an instance of a plugin to the whitelist
    */
    function addValidPluginInstance(address addr) auth(PLUGIN_MANAGER_ROLE) external {
        pluginInstanceWhitelist[addr] = true;
    }

    /**
    * @dev add a contract to the plugin whitelist.
    * @notice Proxy contracts should never be added using this method. Each individual
    *         proxy instance should be added by calling `addValidPluginInstance`
    */
    function addValidPluginContract(bytes32 contractHash) auth(PLUGIN_MANAGER_ROLE) public {
        pluginContractWhitelist[contractHash] = true;
    }

    function addValidPluginContracts(bytes32[] contractHashes) external auth(PLUGIN_MANAGER_ROLE) {
        for (uint8 i = 0; i < contractHashes.length; i++) {
            addValidPluginContract(contractHashes[i]);
        }
    }

    /**
    * @dev removes a contract from the plugin whitelist
    */
    function removeValidPluginContract(bytes32 contractHash) external authP(PLUGIN_MANAGER_ROLE, arr(contractHash)) {
        pluginContractWhitelist[contractHash] = false;
    }

    /**
    * @dev removes an instance of a plugin to the whitelist
    */
    function removeValidPluginInstance(address addr) external authP(PLUGIN_MANAGER_ROLE, arr(addr)) {
        pluginInstanceWhitelist[addr] = false;
    }

    /**
    * @dev enable/disable the plugin whitelist.
    * @notice you better know what you're doing if you are going to disable it
    */
    function useWhitelist(bool useWhitelist) external auth(PLUGIN_MANAGER_ROLE) {
        whitelistDisabled = !useWhitelist;
    }

    /**
    * check if the contract at the provided address is in the plugin whitelist
    */
    function isValidPlugin(address addr) public view returns(bool) {
        if (whitelistDisabled || addr == 0x0) {
            return true;
        }

        // first check pluginInstances
        if (pluginInstanceWhitelist[addr]) {
            return true;
        }

        // if the addr isn't a valid instance, check the contract code
        bytes32 contractHash = getCodeHash(addr);

        return pluginContractWhitelist[contractHash];
    }

    /**
    * @return the hash of the code for the given address
    */
    function getCodeHash(address addr) public view returns(bytes32) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            mstore(o_code, size) // store length in memory
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}