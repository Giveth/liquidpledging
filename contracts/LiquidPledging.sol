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

import "./LiquidPledgingBase.sol";

/// @dev `LiquidPledging` allows for liquid pledging through the use of
///  internal id structures and delegate chaining. All basic operations for
///  handling liquid pledging are supplied as well as plugin features
///  to allow for expanded functionality.
contract LiquidPledging is LiquidPledgingBase {


    /// @notice This is how value enters the system and how pledges are created;
    ///  the ether is sent to the vault, an pledge for the Giver is created (or
    ///  found), the amount of ETH donated in wei is added to the `amount` in
    ///  the Giver's Pledge, and an LP transfer is done to the idReceiver for
    ///  the full amount
    /// @param idGiver The id of the Giver donating; if 0, a new id is created
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    function donate(uint64 idGiver, uint64 idReceiver)
        public payable 
    {
        // TODO: maybe need a separate role here to allow giver creation
        if (idGiver == 0) {
            // default to a 3 day (259200 seconds) commitTime
            idGiver = uint64(addGiver("", "", 259200, ILiquidPledgingPlugin(0x0)));
        }

        PledgeAdmins.PledgeAdmin storage sender = _findAdmin(idGiver);
        require(sender.adminType == PledgeAdminType.Giver);
        require(canPerform(msg.sender, PLEDGE_ADMIN_ROLE, arr(uint(idGiver))));

        uint amount = msg.value;
        require(amount > 0);
        // Sends the `msg.value` (in wei) to the `vault`
        // b/c the vault is a proxy, send & transfer will fail since they only provide 2300
        // gas, and the delegateProxy will sub(gas, 10000) before even making the call
        require(vault.call.value(amount).gas(16000)());

        uint64 idPledge = _findOrCreatePledge(
            idGiver,
            new uint64[](0), // Creates empty array for delegationChain
            0,
            0,
            0,
            Pledges.PledgeState.Pledged
        );

        Pledges.Pledge storage pTo = _findPledge(idPledge);
        pTo.amount += amount;

        Transfer(0, idPledge, amount); // An event

        transfer(idGiver, idPledge, amount, idReceiver); // LP accounting
    }

    /// @notice Transfers amounts between pledges for internal accounting
    /// @param idSender Id of the Admin that is transferring the amount from
    ///  Pledge to Pledge; this admin must have permissions to move the value
    /// @param idPledge Id of the pledge that's moving the value
    /// @param amount Quantity of ETH (in wei) that this pledge is transferring 
    ///  the authority to withdraw from the vault
    /// @param idReceiver Destination of the `amount`, can be a Giver/Project sending
    ///  to a Giver, a Delegate or a Project; a Delegate sending to another
    ///  Delegate, or a Delegate pre-commiting it to a Project 
    function transfer( 
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) authP(PLEDGE_ADMIN_ROLE, arr(uint(idSender), amount)) public 
    {
        idPledge = normalizePledge(idPledge);

        Pledges.Pledge storage p = _findPledge(idPledge);
        PledgeAdmins.PledgeAdmin storage receiver = _findAdmin(idReceiver);
        // PledgeAdmins.PledgeAdmin storage sender = _findAdmin(idSender);

        // _checkAdminOwner(sender);
        require(p.pledgeState == PledgeState.Pledged);

        // If the sender is the owner of the Pledge
        if (p.owner == idSender) {

            if (receiver.adminType == PledgeAdmins.PledgeAdminType.Giver) {
                _transferOwnershipToGiver(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdmins.PledgeAdminType.Project) {
                _transferOwnershipToProject(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdmins.PledgeAdminType.Delegate) {

                uint recieverDIdx = _getDelegateIdx(p, idReceiver);
                if (p.intendedProject > 0 && recieverDIdx != NOTFOUND) {
                    // if there is an intendedProject and the receiver is in the delegationChain,
                    // then we want to preserve the delegationChain as this is a veto of the
                    // intendedProject by the owner

                    if (recieverDIdx == p.delegationChain.length - 1) {
                        uint64 toPledge = _findOrCreatePledge(
                            p.owner,
                            p.delegationChain,
                            0,
                            0,
                            p.oldPledge,
                            Pledges.PledgeState.Pledged);
                        _doTransfer(idPledge, toPledge, amount);
                    } else {
                        _undelegate(idPledge, amount, p.delegationChain.length - receiverDIdx - 1);
                    }
                } else {
                    // owner is not vetoing an intendedProject and is transferring the pledge to a delegate,
                    // so we want to reset the delegationChain
                    idPledge  = _undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length
                    );
                    _appendDelegate(idPledge, amount, idReceiver);
                }

            } else {
                // This should never be reached as the reciever.adminType
                // should always be either a Giver, Project, or Delegate
                assert(false);
            }
            return;
        }

        // If the sender is a Delegate
        uint senderDIdx = _getDelegateIdx(p, idSender);
        if (senderDIdx != NOTFOUND) {

            // And the receiver is another Giver
            if (receiver.adminType == PledgeAdmins.PledgeAdminType.Giver) {
                // Only transfer to the Giver who owns the pldege
                assert(p.owner == idReceiver);
                _undelegate(idPledge, amount, p.delegationChain.length);
                return;
            }

            // And the receiver is another Delegate
            if (receiver.adminType == PledgeAdmins.PledgeAdminType.Delegate) {
                uint receiverDIdx = _getDelegateIdx(p, idReceiver);

                // And not in the delegationChain
                if (receiverDIdx == NOTFOUND) {
                    idPledge = _undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    _appendDelegate(idPledge, amount, idReceiver);

                // And part of the delegationChain and is after the sender, then
                //  all of the other delegates after the sender are removed and
                //  the receiver is appended at the end of the delegationChain
                } else if (receiverDIdx > senderDIdx) {
                    idPledge = _undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    _appendDelegate(idPledge, amount, idReceiver);

                // And is already part of the delegate chain but is before the
                //  sender, then the sender and all of the other delegates after
                //  the RECEIVER are removed from the delegationChain
                } else if (receiverDIdx <= senderDIdx) {//TODO Check for Game Theory issues (from Arthur) this allows the sender to sort of go komakosi and remove himself and the delegates between himself and the receiver... should this authority be allowed?
                    _undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - receiverDIdx - 1
                    );
                }
                return;
            }

            // And the receiver is a Project, all the delegates after the sender
            //  are removed and the amount is pre-committed to the project
            if (receiver.adminType == PledgeAdmins.PledgeAdminType.Project) {
                idPledge = _undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length - senderDIdx - 1
                );
                _proposeAssignProject(idPledge, amount, idReceiver);
                return;
            }
        }
        assert(false);  // When the sender is not an owner or a delegate
    }

    /// @notice Authorizes a payment be made from the `vault` can be used by the
    ///  Giver to veto a pre-committed donation from a Delegate to an
    ///  intendedProject
    /// @param idPledge Id of the pledge that is to be redeemed into ether
    /// @param amount Quantity of ether (in wei) to be authorized
    function withdraw(uint64 idPledge, uint amount) public {
        idPledge = normalizePledge(idPledge); // Updates pledge info 

        Pledges.Pledge storage p = _findPledge(idPledge);
        require(p.pledgeState == PledgeState.Pledged);

        PledgeAdmins.PledgeAdmin storage owner = _findAdmin(p.owner);
        require(canPerform(msg.sender, PLEDGE_ADMIN_ROLE, arr(uint(p.owner))));

        uint64 idNewPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Paying
        );

        _doTransfer(idPledge, idNewPledge, amount);

        vault.authorizePayment(bytes32(idNewPledge), owner.addr, amount);
    }

    /// @notice `onlyVault` Confirms a withdraw request changing the Pledges.PledgeState
    ///  from Paying to Paid
    /// @param idPledge Id of the pledge that is to be withdrawn
    /// @param amount Quantity of ether (in wei) to be withdrawn
    function confirmPayment(uint64 idPledge, uint amount) public onlyVault {
        //TODO don't fetch entire pledge
        Pledges.Pledge storage p = _findPledge(idPledge);

        require(p.pledgeState == Pledges.PledgeState.Paying);

        uint64 idNewPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Paid
        );

        _doTransfer(idPledge, idNewPledge, amount);
    }

    /// @notice `onlyVault` Cancels a withdraw request, changing the Pledges.PledgeState
    ///  from Paying back to Pledged
    /// @param idPledge Id of the pledge that's withdraw is to be canceled
    /// @param amount Quantity of ether (in wei) to be canceled
    function cancelPayment(uint64 idPledge, uint amount) public onlyVault {
        Pledges.Pledge storage p = _findPledge(idPledge);

        require(p.pledgeState == Pledges.PledgeState.Paying);

        // When a payment is canceled, never is assigned to a project.
        uint64 idOldPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            Pledges.PledgeState.Pledged
        );

        idOldPledge = normalizePledge(idOldPledge);

        _doTransfer(idPledge, idOldPledge, amount);
    }

    /// @notice Changes the `project.canceled` flag to `true`; cannot be undone
    /// @param idProject Id of the project that is to be canceled
    function cancelProject(uint64 idProject) authP(PLEDGE_ADMIN_ROLE, arr(uint(idProject))) public {
        PledgeAdmins.PledgeAdmin storage project = _findAdmin(idProject);
        // _checkAdminOwner(project);
        project.canceled = true;

        CancelProject(idProject);
    }

    /// @notice Transfers `amount` in `idPledge` back to the `oldPledge` that
    ///  that sent it there in the first place, a Ctrl-z 
    /// @param idPledge Id of the pledge that is to be canceled
    /// @param amount Quantity of ether (in wei) to be transfered to the 
    ///  `oldPledge`
    function cancelPledge(uint64 idPledge, uint amount) public {//authP(PLEDGE_ADMIN_ROLE, arr(uint(idPledge))) public {
        idPledge = normalizePledge(idPledge);

        Pledges.Pledge storage p = _findPledge(idPledge);
        require(p.oldPledge != 0);

        require(canPerform(msg.sender, PLEDGE_ADMIN_ROLE, arr(uint(p.owner))));
        // PledgeAdmins.PledgeAdmin storage a = _findAdmin(p.owner);
        // _checkAdminOwner(a);

        uint64 oldPledge = _getOldestPledgeNotCanceled(p.oldPledge);
        _doTransfer(idPledge, oldPledge, amount);
    }


////////
// Multi pledge methods
////////

    // @dev This set of functions makes moving a lot of pledges around much more
    // efficient (saves gas) than calling these functions in series
    
    
    /// @dev Bitmask used for dividing pledge amounts in Multi pledge methods
    uint constant D64 = 0x10000000000000000;

    /// @notice Transfers multiple amounts within multiple Pledges in an
    ///  efficient single call 
    /// @param idSender Id of the Admin that is transferring the amounts from
    ///  all the Pledges; this admin must have permissions to move the value
    /// @param pledgesAmounts An array of Pledge amounts and the idPledges with 
    ///  which the amounts are associated; these are extrapolated using the D64
    ///  bitmask
    /// @param idReceiver Destination of the `pledesAmounts`, can be a Giver or 
    ///  Project sending to a Giver, a Delegate or a Project; a Delegate sending
    ///  to another Delegate, or a Delegate pre-commiting it to a Project 
    function mTransfer(
        uint64 idSender,
        uint[] pledgesAmounts,
        uint64 idReceiver
    ) public 
    {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            transfer(idSender, idPledge, amount, idReceiver);
        }
    }

    /// @notice Authorizes multiple amounts within multiple Pledges to be
    ///  withdrawn from the `vault` in an efficient single call 
    /// @param pledgesAmounts An array of Pledge amounts and the idPledges with 
    ///  which the amounts are associated; these are extrapolated using the D64
    ///  bitmask
    function mWithdraw(uint[] pledgesAmounts) public {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            withdraw(idPledge, amount);
        }
    }

    /// @notice `mConfirmPayment` allows for multiple pledges to be confirmed
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mConfirmPayment(uint[] pledgesAmounts) public {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            confirmPayment(idPledge, amount);
        }
    }

    /// @notice `mCancelPayment` allows for multiple pledges to be canceled
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mCancelPayment(uint[] pledgesAmounts) public {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            cancelPayment(idPledge, amount);
        }
    }

    /// @notice `mNormalizePledge` allows for multiple pledges to be
    ///  normalized efficiently
    /// @param pledges An array of pledge IDs
    function mNormalizePledge(uint64[] pledges) public {
        for (uint i = 0; i < pledges.length; i++ ) {
            normalizePledge( pledges[i] );
        }
    }

////////
// Private methods
///////

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

    /// @notice Only affects pledges with the Pledged Pledges.PledgeState for 2 things:
    ///   #1: Checks if the pledge should be committed. This means that
    ///       if the pledge has an intendedProject and it is past the
    ///       commitTime, it changes the owner to be the proposed project
    ///       (The UI will have to read the commit time and manually do what
    ///       this function does to the pledge for the end user
    ///       at the expiration of the commitTime)
    ///
    ///   #2: Checks to make sure that if there has been a cancellation in the
    ///       chain of projects, the pledge's owner has been changed
    ///       appropriately.
    ///
    /// This function can be called by anybody at anytime on any pledge.
    ///  In general it can be called to force the calls of the affected 
    ///  plugins, which also need to be predicted by the UI
    /// @param idPledge This is the id of the pledge that will be normalized
    /// @return The normalized Pledge!
    function normalizePledge(uint64 idPledge) public returns(uint64) {
        Pledges.Pledge storage p = _findPledge(idPledge);

        // Check to make sure this pledge hasn't already been used 
        // or is in the process of being used
        if (p.pledgeState != Pledges.PledgeState.Pledged) {
            return idPledge;
        }

        // First send to a project if it's proposed and committed
        if ((p.intendedProject > 0) && ( _getTime() > p.commitTime)) {
            uint64 oldPledge = _findOrCreatePledge(
                p.owner,
                p.delegationChain,
                0,
                0,
                p.oldPledge,
                Pledges.PledgeState.Pledged
            );
            uint64 toPledge = _findOrCreatePledge(
                p.intendedProject,
                new uint64[](0),
                0,
                0,
                oldPledge,
                Pledges.PledgeState.Pledged
            );
            _doTransfer(idPledge, toPledge, p.amount);
            idPledge = toPledge;
            p = _findPledge(idPledge);
        }

        toPledge = _getOldestPledgeNotCanceled(idPledge);
        if (toPledge != idPledge) {
            _doTransfer(idPledge, toPledge, p.amount);
        }

        return toPledge;
    }

/////////////
// Plugins
/////////////

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
    ) internal returns (uint allowedAmount) {

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
    ) internal returns (uint allowedAmount) {
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
    ) internal returns (uint allowedAmount) {
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

    function getTime() public view returns(uint) {
        return _getTime();
    }

    // Event Declarations
    event Transfer(uint indexed from, uint indexed to, uint amount);
    event CancelProject(uint indexed idProject);

}
