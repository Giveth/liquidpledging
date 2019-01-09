pragma solidity ^0.4.24;

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

contract LiquidPledgingPlugins is AragonApp, LiquidPledgingStorage {

    // bytes32 constant public PLUGIN_MANAGER_ROLE = keccak256("PLUGIN_MANAGER_ROLE");
    bytes32 constant public _PLUGIN_MANAGER_ROLE = 0xd3c76383116f5940be0ff28f44aa486f936c612285d02d30e852699826c34d26;

    string internal constant ERROR_INVALID_PLUGIN = "LIQUIDPLEDGING_PLUGIN_NOT_WHITELISTED";

    /**
    * @dev adds an instance of a plugin to the whitelist
    */
    function addValidPluginInstance(address addr) auth(_PLUGIN_MANAGER_ROLE) external {
        pluginInstanceWhitelist[addr] = true;
    }

    /**
    * @dev add a contract to the plugin whitelist.
    * @notice Proxy contracts should never be added using this method. Each individual
    *         proxy instance should be added by calling `addValidPluginInstance`
    */
    function addValidPluginContract(bytes32 contractHash) auth(_PLUGIN_MANAGER_ROLE) public {
        pluginContractWhitelist[contractHash] = true;
    }

    function addValidPluginContracts(bytes32[] contractHashes) external auth(_PLUGIN_MANAGER_ROLE) {
        for (uint8 i = 0; i < contractHashes.length; i++) {
            addValidPluginContract(contractHashes[i]);
        }
    }

    /**
    * @dev removes a contract from the plugin whitelist
    */
    function removeValidPluginContract(bytes32 contractHash) external authP(_PLUGIN_MANAGER_ROLE, arr(contractHash)) {
        pluginContractWhitelist[contractHash] = false;
    }

    /**
    * @dev removes an instance of a plugin to the whitelist
    */
    function removeValidPluginInstance(address addr) external authP(_PLUGIN_MANAGER_ROLE, arr(addr)) {
        pluginInstanceWhitelist[addr] = false;
    }

    /**
    * @dev enable/disable the plugin whitelist.
    * @notice you better know what you're doing if you are going to disable it
    */
    function useWhitelist(bool shouldUseWhitelist) external auth(_PLUGIN_MANAGER_ROLE) {
        whitelistDisabled = !shouldUseWhitelist;
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
            // retrieve the size of the code
            let size := extcodesize(addr)
            // allocate output byte array
            o_code := mload(0x40)
            mstore(o_code, size) // store length in memory
            // actually retrieve the code
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }

    // we provide a pure function here to satisfy the ILiquidPledging interface
    // the compiler will generate this function for public constant variables, but will not 
    // recognize that the interface has been satisfied and thus will not generate the bytecode
    function PLUGIN_MANAGER_ROLE() external pure returns (bytes32) { return _PLUGIN_MANAGER_ROLE; }
}