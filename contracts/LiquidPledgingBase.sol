pragma solidity ^0.4.11;

/*
    Copyright 2017, Jordi Baylina
    Contributors: Adrià Massanet <adria@codecontext.io>, RJ Ewing, Griff
    Green, Arthur Lunn

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

import "./ILiquidPledgingPlugin.sol";
import "giveth-common-contracts/contracts/Escapable.sol";
import "./PledgeAdmins.sol";
import "./Pledges.sol";
import "./LiquidPledgingStorage.sol";

/// @dev This is an interface for `LPVault` which serves as a secure storage for
///  the ETH that backs the Pledges, only after `LiquidPledging` authorizes
///  payments can Pledges be converted for ETH
interface LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount) public;
    function () public payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquidPledging's most basic functions, mostly handling and searching the
///  data structures
contract LiquidPledgingBase is LiquidPledgingStorage, PledgeAdmins, Pledges, Escapable {

    LPVault public vault;
    

/////////////
// Modifiers
/////////////

    /// @dev The `vault`is the only addresses that can call a function with this
    ///  modifier
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }


///////////////
// Constructor
///////////////

    /// @notice The Constructor creates `LiquidPledgingBase` on the blockchain
    /// @param _vault The vault where the ETH backing the pledges is stored
    function LiquidPledgingBase(
        address _storage,
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) LiquidPledgingStorage(_storage)
      PledgeAdmins(_storage)
      Pledges(_storage)
      Escapable(_escapeHatchCaller, _escapeHatchDestination) public 
    {
        vault = LPVault(_vault); // Assigns the specified vault
    }

/////////////////////////////
// Public constant functions
/////////////////////////////

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
    function getDelegate(uint idPledge, uint idxDelegate) public view returns(
        uint idDelegate,
        address addr,
        string name
    ) {
        idDelegate = getPledgeDelegate(idPledge, idxDelegate);
        addr = getAdminAddr(idDelegate);
        name = getAdminName(idDelegate);
    }

////////////////////
// Internal methods
////////////////////

    /// @notice A check to see if the msg.sender is the owner or the
    ///  plugin contract for a specific Admin
    /// @param idAdmin The id of the admin being checked
    function checkAdminOwner(uint idAdmin) internal constant {
        require(msg.sender == getAdminAddr(idAdmin) || msg.sender == getAdminPlugin(idAdmin));
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param p The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function maxCommitTime(Pledge p) internal view returns(uint commitTime) {
        uint adminsSize = numberOfPledgeAdmins();
        require(adminsSize >= p.owner);

        commitTime = getAdminCommitTime(p.owner); // start with the owner's commitTime

        for (uint i = 0; i < p.delegationChain.length; i++) {
            require(adminsSize >= p.delegationChain[i]);
            uint delegateCommitTime = getAdminCommitTime(p.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (delegateCommitTime > commitTime) {
                commitTime = delegateCommitTime;
            }
        }
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges 
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function getOldestPledgeNotCanceled(
        uint64 idPledge
    ) internal view returns(uint64)
    {
        if (idPledge == 0) {
            return 0;
        }

        uint owner = getPledgeOwner(idPledge);

        PledgeAdminType adminType = getAdminType(owner);
        if (adminType == PledgeAdminType.Giver) { 
            return idPledge;
        }
        assert(adminType == PledgeAdminType.Project);

        if (!isProjectCanceled(owner)) {
            return idPledge;
        }

        uint64 oldPledge = uint64(getPledgeOldPledge(idPledge));
        return getOldestPledgeNotCanceled(oldPledge);
    }
}
