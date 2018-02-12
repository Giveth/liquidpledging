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
// import "giveth-common-contracts/contracts/Escapable.sol";
import "./EscapableApp.sol";
import "./PledgeAdmins.sol";
import "./Pledges.sol";

/// @dev This is an interface for `LPVault` which serves as a secure storage for
///  the ETH that backs the Pledges, only after `LiquidPledging` authorizes
///  payments can Pledges be converted for ETH
interface ILPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount) public;
    function () public payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquidPledging's most basic functions, mostly handling and searching the
///  data structures
contract LiquidPledgingBase is PledgeAdmins, Pledges, EscapableApp {

    // Event Declarations
    event Transfer(uint indexed from, uint indexed to, uint amount);
    event CancelProject(uint indexed idProject);

    ILPVault public vault;
    
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

    function initialize(address _escapeHatchDestination) onlyInit public {
        require(false); // overload the EscapableApp
    }

    /// @param _vault The vault where the ETH backing the pledges is stored
    /// @param _escapeHatchDestination The address of a safe location (usu a
    ///  Multisig) to send the ether held in this contract; if a neutral address
    ///  is required, the WHG Multisig is an option:
    ///  0x8Ff920020c8AD673661c8117f2855C384758C572 
    function initialize(address _vault, address _escapeHatchDestination) onlyInit public {
        super.initialize(_escapeHatchDestination);
        require(_vault != 0x0);

        vault = ILPVault(_vault);

        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
    }


/////////////////////////////
// Public constant functions
/////////////////////////////

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
    function getPledgeDelegate(uint64 idPledge, uint64 idxDelegate) public view returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage p = _findPledge(idPledge);
        idDelegate = p.delegationChain[idxDelegate - 1];
        PledgeAdmin storage delegate = _findAdmin(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }

////////////////////
// Internal methods
////////////////////

    /// @notice `transferOwnershipToProject` allows for the transfer of
    ///  ownership to the project, but it can also be called by a project
    ///  to un-delegate everyone by setting one's own id for the idReceiver
    /// @param idPledge the id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the project (or self to un-delegate)
    function _transferOwnershipToProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledges.Pledge storage p = _findPledge(idPledge);

        // Ensure that the pledge is not already at max pledge depth
        // and the project has not been canceled
        require(_getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!_isProjectCanceled(idReceiver));

        uint64 oldPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Pledged
        );
        uint64 toPledge = _findOrCreatePledge(
            idReceiver,                     // Set the new owner
            new uint64[](0),                // clear the delegation chain
            0,
            0,
            uint64(oldPledge),
            Pledges.PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }   


    /// @notice `transferOwnershipToGiver` allows for the transfer of
    ///  value back to the Giver, value is placed in a pledged state
    ///  without being attached to a project, delegation chain, or time line.
    /// @param idPledge the id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the pledge
    function _transferOwnershipToGiver(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        uint64 toPledge = _findOrCreatePledge(
            idReceiver,
            new uint64[](0),
            0,
            0,
            0,
            Pledges.PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge the id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's being chained.
    /// @param idReceiver The delegate to be added at the end of the chain
    function _appendDelegate(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledges.Pledge storage p = _findPledge(idPledge);

        require(p.delegationChain.length < MAX_DELEGATES);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length + 1
        );
        for (uint i = 0; i < p.delegationChain.length; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }

        // Make the last item in the array the idReceiver
        newDelegationChain[p.delegationChain.length] = idReceiver;

        uint64 toPledge = _findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge the id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's shifted from delegates.
    /// @param q Number (or depth) of delegates to remove
    /// @return toPledge The id for the pledge being adjusted or created
    function _undelegate(
        uint64 idPledge,
        uint amount,
        uint q
    ) internal returns (uint64 toPledge)
    {
        Pledges.Pledge storage p = _findPledge(idPledge);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length - q
        );

        for (uint i = 0; i < p.delegationChain.length - q; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }
        toPledge = _findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `proposeAssignProject` proposes the assignment of a pledge
    ///  to a specific project.
    /// @dev This function should potentially be named more specifically.
    /// @param idPledge the id of the pledge that will be assigned.
    /// @param amount Quantity of value this pledge leader would be assigned.
    /// @param idReceiver The project this pledge will potentially 
    ///  be assigned to.
    function _proposeAssignProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledges.Pledge storage p = _findPledge(idPledge);

        require(_getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!_isProjectCanceled(idReceiver));

        uint64 toPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            idReceiver,
            uint64(_getTime() + _maxCommitTime(p)),
            p.oldPledge,
            Pledges.PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `doTransfer` is designed to allow for pledge amounts to be 
    ///  shifted around internally.
    /// @param from This is the id of the pledge from which value will be transfered.
    /// @param to This is the id of the pledge that value will be transfered to.
    /// @param _amount The amount of value that will be transfered.
    function _doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = _callPlugins(true, from, to, _amount);
        if (from == to) {
            return;
        }
        if (amount == 0) {
            return;
        }

        Pledges.Pledge storage pFrom = _findPledge(from);
        Pledges.Pledge storage pTo = _findPledge(to);

        require(pFrom.amount >= amount);
        pFrom.amount -= amount;
        pTo.amount += amount;

        Transfer(from, to, amount);
        _callPlugins(false, from, to, amount);
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param p The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function _maxCommitTime(Pledge p) internal view returns(uint64 commitTime) {
        PledgeAdmin storage a = _findAdmin(p.owner);
        commitTime = a.commitTime; // start with the owner's commitTime

        for (uint i = 0; i < p.delegationChain.length; i++) {
            a = _findAdmin(p.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (a.commitTime > commitTime) {
                commitTime = a.commitTime;
            }
        }
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges 
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function _getOldestPledgeNotCanceled(
        uint64 idPledge
    ) internal view returns(uint64)
    {
        if (idPledge == 0) {
            return 0;
        }

        Pledge storage p = _findPledge(idPledge);
        PledgeAdmin storage admin = _findAdmin(p.owner);
        
        if (admin.adminType == PledgeAdminType.Giver) {
            return idPledge;
        }

        assert(admin.adminType == PledgeAdminType.Project);
        if (!_isProjectCanceled(p.owner)) {
            return idPledge;
        }

        return _getOldestPledgeNotCanceled(p.oldPledge);
    }

    /// @notice `callPlugin` is used to trigger the general functions in the
    ///  plugin for any actions needed before and after a transfer happens.
    ///  Specifically what this does in relation to the plugin is something
    ///  that largely depends on the functions of that plugin. This function
    ///  is generally called in pairs, once before, and once after a transfer.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param adminId This should be the Id of the *trusted* individual
    ///  who has control over this plugin.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param context The situation that is triggering the plugin. See plugin
    ///  for a full description of contexts.
    /// @param amount The amount of value that is being transfered.
    function _callPlugin(
        bool before,
        uint64 adminId,
        uint64 fromPledge,
        uint64 toPledge,
        uint64 context,
        uint amount
    ) internal returns (uint allowedAmount) 
    {

        uint newAmount;
        allowedAmount = amount;
        PledgeAdmins.PledgeAdmin storage admin = _findAdmin(adminId);

        // Checks admin has a plugin assigned and a non-zero amount is requested
        if (address(admin.plugin) != 0 && allowedAmount > 0) {
            // There are two seperate functions called in the plugin.
            // One is called before the transfer and one after
            if (before) {
                newAmount = admin.plugin.beforeTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                admin.plugin.afterTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
            }
        }
    }

    /// @notice `callPluginsPledge` is used to apply plugin calls to
    ///  the delegate chain and the intended project if there is one.
    ///  It does so in either a transferring or receiving context based
    ///  on the `p` and  `fromPledge` parameters.
    /// @param before This toggle determines whether the plugin call is occuring
    ///  before or after a transfer.
    /// @param idPledge This is the id of the pledge on which this plugin
    ///  is being called.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param amount The amount of value that is being transfered.
    function _callPluginsPledge(
        bool before,
        uint64 idPledge,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) 
    {
        // Determine if callPlugin is being applied in a receiving
        // or transferring context
        uint64 offset = idPledge == fromPledge ? 0 : 256;
        allowedAmount = amount;
        Pledges.Pledge storage p = _findPledge(idPledge);

        // Always call the plugin on the owner
        allowedAmount = _callPlugin(
            before,
            p.owner,
            fromPledge,
            toPledge,
            offset,
            allowedAmount
        );

        // Apply call plugin to all delegates
        for (uint64 i = 0; i < p.delegationChain.length; i++) {
            allowedAmount = _callPlugin(
                before,
                p.delegationChain[i],
                fromPledge,
                toPledge,
                offset + i + 1,
                allowedAmount
            );
        }

        // If there is an intended project also call the plugin in
        // either a transferring or receiving context based on offset
        // on the intended project
        if (p.intendedProject > 0) {
            allowedAmount = _callPlugin(
                before,
                p.intendedProject,
                fromPledge,
                toPledge,
                offset + 255,
                allowedAmount
            );
        }
    }

    /// @notice `callPlugins` calls `callPluginsPledge` once for the transfer
    ///  context and once for the receiving context. The aggregated 
    ///  allowed amount is then returned.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param fromPledge This is the Id from which value is being transferred.
    /// @param toPledge This is the Id that value is being transferred to.
    /// @param amount The amount of value that is being transferred.
    function _callPlugins(
        bool before,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) 
    {
        allowedAmount = amount;

        // Call the pledges plugins in the transfer context
        allowedAmount = _callPluginsPledge(
            before,
            fromPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );

        // Call the pledges plugins in the receive context
        allowedAmount = _callPluginsPledge(
            before,
            toPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );
    }

/////////////
// Test functions
/////////////

    /// @notice Basic helper function to return the current time
    function _getTime() internal view returns (uint) {
        return now;
    }
}
