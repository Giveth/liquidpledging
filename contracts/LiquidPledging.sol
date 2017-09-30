pragma solidity ^0.4.11;

import "./LiquidPledgingBase.sol";


contract LiquidPledging is LiquidPledgingBase {


//////
// Constructor
//////

    // This constructor actualy also calls the constructor for the
    // `LiquidPledgingBase` contract
    function LiquidPledging(address _vault) LiquidPledgingBase(_vault) {
    }

    /// @notice This is how value enters into the system which creates notes. The
    ///  token of value goes into the vault and then the amount in the Note
    /// relevant to this donor without delegates is increased.
    ///  After that, a normal transfer is done to the idReceiver.
    /// @param idDonor Identifier of the donor thats donating.
    /// @param idReceiver To whom it's transfered. Can be the same donor, another
    ///  donor, a delegate or a project
    function donate(uint64 idDonor, uint64 idReceiver) payable {// TODO change to `pledge()`
        if (idDonor == 0) {
            idDonor = addDonor('', 259200, ILiquidPledgingPlugin(0x0)); // default to 3 day commitTime
        }

        NoteManager storage sender = findManager(idDonor);

        checkManagerOwner(sender);

        require(sender.managerType == NoteManagerType.Donor);

        uint amount = msg.value;

        require(amount > 0);

        vault.transfer(amount); // transfers the baseToken to the Vault
        uint64 idNote = findNote(
            idDonor,
            new uint64[](0), //what is new
            0,
            0,
            0,
            PaymentState.NotPaid);


        Note storage nTo = findNote(idNote);
        nTo.amount += amount;

        Transfer(0, idNote, amount);

        transfer(idDonor, idNote, amount, idReceiver);
    }


    /// @notice This is the main function to move value from one Note to the other
    /// @param idSender ID of the donor, delegate or project manager that is transfering
    ///  the funds from Note to Note. This manager must have permisions to move the value
    /// @param idNote Id of the note that's moving the value
    /// @param amount Quantity of value that's being moved
    /// @param idReceiver Destination of the value, can be a donor sending to a donor or
    ///  a delegate, a delegate to another delegate or a project to precommit it to that project
    function transfer(uint64 idSender, uint64 idNote, uint amount, uint64 idReceiver) {

        idNote = normalizeNote(idNote);

        Note storage n = findNote(idNote);
        NoteManager storage receiver = findManager(idReceiver);
        NoteManager storage sender = findManager(idSender);

        checkManagerOwner(sender);
        require(n.paymentState == PaymentState.NotPaid);

        // If the sender is the owner
        if (n.owner == idSender) {
            if (receiver.managerType == NoteManagerType.Donor) {
                transferOwnershipToDonor(idNote, amount, idReceiver);
            } else if (receiver.managerType == NoteManagerType.Project) {
                transferOwnershipToProject(idNote, amount, idReceiver);
            } else if (receiver.managerType == NoteManagerType.Delegate) {
                appendDelegate(idNote, amount, idReceiver);
            } else {
                assert(false);
            }
            return;
        }

        // If the sender is a delegate
        uint senderDIdx = getDelegateIdx(n, idSender);
        if (senderDIdx != NOTFOUND) {

            // If the receiver is another donor
            if (receiver.managerType == NoteManagerType.Donor) {
                // Only accept to change to the original donor to remove all delegates
                assert(n.owner == idReceiver);
                undelegate(idNote, amount, n.delegationChain.length);
                return;
            }

            // If the receiver is another delegate
            if (receiver.managerType == NoteManagerType.Delegate) {
                uint receiverDIdx = getDelegateIdx(n, idReceiver);

                // If the receiver is not in the delegate list
                if (receiverDIdx == NOTFOUND) {
                    undelegate(idNote, amount, n.delegationChain.length - senderDIdx - 1);
                    appendDelegate(idNote, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // after the sender, then all of the other delegates after the sender are
                // removed and the receiver is appended at the end of the delegation chain
                } else if (receiverDIdx > senderDIdx) {
                    undelegate(idNote, amount, n.delegationChain.length - senderDIdx - 1);
                    appendDelegate(idNote, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // before the sender, then the sender and all of the other
                // delegates after the RECEIVER are revomved from the chain,
                // this is interesting because the delegate undelegates from the
                // delegates that delegated to this delegate... game theory issues? should this be allowed
                } else if (receiverDIdx <= senderDIdx) {
                    undelegate(idNote, amount, n.delegationChain.length - receiverDIdx -1);
                }
                return;
            }

            // If the delegate wants to support a project, they undelegate all
            // the delegates after them in the chain and choose a project
            if (receiver.managerType == NoteManagerType.Project) {
                undelegate(idNote, amount, n.delegationChain.length - senderDIdx - 1);
                proposeAssignProject(idNote, amount, idReceiver);
                return;
            }
        }
        assert(false);  // It is not the owner nor any delegate.
    }


    /// @notice This method is used to withdraw value from the system. This can be used
    ///  by the donors to avoid committing the donation or by project manager to use
    ///  the Ether.
    /// @param idNote Id of the note that wants to be withdrawed.
    /// @param amount Quantity of Ether that wants to be withdrawed.
    function withdraw(uint64 idNote, uint amount) {

        idNote = normalizeNote(idNote);

        Note storage n = findNote(idNote);

        require(n.paymentState == PaymentState.NotPaid);

        NoteManager storage owner = findManager(n.owner);

        checkManagerOwner(owner);

        uint64 idNewNote = findNote(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldNote,
            PaymentState.Paying
        );

        doTransfer(idNote, idNewNote, amount);

        vault.authorizePayment(bytes32(idNewNote), owner.addr, amount);
    }

    /// @notice Method called by the vault to confirm a payment.
    /// @param idNote Id of the note that wants to be withdrawed.
    /// @param amount Quantity of Ether that wants to be withdrawed.
    function confirmPayment(uint64 idNote, uint amount) onlyVault {
        Note storage n = findNote(idNote);

        require(n.paymentState == PaymentState.Paying);

        // Check the project is not canceled in the while.
        require(getOldestNoteNotCanceled(idNote) == idNote);

        uint64 idNewNote = findNote(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldNote,
            PaymentState.Paid
        );

        doTransfer(idNote, idNewNote, amount);
    }

    /// @notice Method called by the vault to cancel a payment.
    /// @param idNote Id of the note that wants to be canceled for withdraw.
    /// @param amount Quantity of Ether that wants to be rolled back.
    function cancelPayment(uint64 idNote, uint amount) onlyVault {
        Note storage n = findNote(idNote);

        require(n.paymentState == PaymentState.Paying); //TODO change to revert

        // When a payment is cacnceled, never is assigned to a project.
        uint64 oldNote = findNote(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldNote,
            PaymentState.NotPaid
        );

        oldNote = normalizeNote(oldNote);

        doTransfer(idNote, oldNote, amount);
    }

    /// @notice Method called to cancel this project.
    /// @param idProject Id of the projct that wants to be canceled.
    function cancelProject(uint64 idProject) {
        NoteManager storage project = findManager(idProject);
        checkManagerOwner(project);
        project.canceled = true;
    }


    function cancelNote(uint64 idNote, uint amount) {
        idNote = normalizeNote(idNote);

        Note storage n = findNote(idNote);

        NoteManager storage m = findManager(n.owner);
        checkManagerOwner(m);

        doTransfer(idNote, n.oldNote, amount);
    }


////////
// Multi note methods
////////

    // This set of functions makes moving a lot of notes around much more
    // efficient (saves gas) than calling these functions in series
    uint constant D64 = 0x10000000000000000;
    function mTransfer(uint64 idSender, uint[] notesAmounts, uint64 idReceiver) {
        for (uint i = 0; i < notesAmounts.length; i++ ) {
            uint64 idNote = uint64( notesAmounts[i] & (D64-1) );
            uint amount = notesAmounts[i] / D64;

            transfer(idSender, idNote, amount, idReceiver);
        }
    }

    function mWithdraw(uint[] notesAmounts) {
        for (uint i = 0; i < notesAmounts.length; i++ ) {
            uint64 idNote = uint64( notesAmounts[i] & (D64-1) );
            uint amount = notesAmounts[i] / D64;

            withdraw(idNote, amount);
        }
    }

    function mConfirmPayment(uint[] notesAmounts) {
        for (uint i = 0; i < notesAmounts.length; i++ ) {
            uint64 idNote = uint64( notesAmounts[i] & (D64-1) );
            uint amount = notesAmounts[i] / D64;

            confirmPayment(idNote, amount);
        }
    }

    function mCancelPayment(uint[] notesAmounts) {
        for (uint i = 0; i < notesAmounts.length; i++ ) {
            uint64 idNote = uint64( notesAmounts[i] & (D64-1) );
            uint amount = notesAmounts[i] / D64;

            cancelPayment(idNote, amount);
        }
    }

    function mNormalizeNote(uint[] notes) returns(uint64) {
        for (uint i = 0; i < notes.length; i++ ) {
            uint64 idNote = uint64( notes[i] & (D64-1) );

            normalizeNote(idNote);
        }
    }

////////
// Private methods
///////

    // this function is obvious, but it can also be called to undelegate everyone
    // by setting your self as teh idReceiver
    function transferOwnershipToProject(uint64 idNote, uint amount, uint64 idReceiver) internal  {
        Note storage n = findNote(idNote);

        require(getNoteLevel(n) < MAX_INTERPROJECT_LEVEL);
        uint64 oldNote = findNote(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldNote,
            PaymentState.NotPaid);
        uint64 toNote = findNote(
            idReceiver,
            new uint64[](0),
            0,
            0,
            oldNote,
            PaymentState.NotPaid);
        doTransfer(idNote, toNote, amount);
    }

    function transferOwnershipToDonor(uint64 idNote, uint amount, uint64 idReceiver) internal  {
        uint64 toNote = findNote(
                idReceiver,
                new uint64[](0),
                0,
                0,
                0,
                PaymentState.NotPaid);
        doTransfer(idNote, toNote, amount);
    }

    function appendDelegate(uint64 idNote, uint amount, uint64 idReceiver) internal  {
        Note storage n= findNote(idNote);

        require(n.delegationChain.length < MAX_DELEGATES); //TODO change to revert and say the error
        uint64[] memory newDelegationChain = new uint64[](n.delegationChain.length + 1);
        for (uint i=0; i<n.delegationChain.length; i++) {
            newDelegationChain[i] = n.delegationChain[i];
        }

        // Make the last item in the array the idReceiver
        newDelegationChain[n.delegationChain.length] = idReceiver;

        uint64 toNote = findNote(
                n.owner,
                newDelegationChain,
                0,
                0,
                n.oldNote,
                PaymentState.NotPaid);
        doTransfer(idNote, toNote, amount);
    }

    /// @param q Unmber of undelegations
    function undelegate(uint64 idNote, uint amount, uint q) internal {
        Note storage n = findNote(idNote);
        uint64[] memory newDelegationChain = new uint64[](n.delegationChain.length - q);
        for (uint i=0; i<n.delegationChain.length - q; i++) {
            newDelegationChain[i] = n.delegationChain[i];
        }
        uint64 toNote = findNote(
                n.owner,
                newDelegationChain,
                0,
                0,
                n.oldNote,
                PaymentState.NotPaid);
        doTransfer(idNote, toNote, amount);
    }


    function proposeAssignProject(uint64 idNote, uint amount, uint64 idReceiver) internal {// Todo rename
        Note storage n = findNote(idNote);

        require(getNoteLevel(n) < MAX_SUBPROJECT_LEVEL);

        uint64 toNote = findNote(
                n.owner,
                n.delegationChain,
                idReceiver,
                uint64(getTime() + maxCommitTime(n)),
                n.oldNote,
                PaymentState.NotPaid);
        doTransfer(idNote, toNote, amount);
    }

    function doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = callPlugins(true, from, to, _amount);
        if (from == to) return;
        if (amount == 0) return;
        Note storage nFrom = findNote(from);
        Note storage nTo = findNote(to);
        require(nFrom.amount >= amount);
        nFrom.amount -= amount;
        nTo.amount += amount;

        Transfer(from, to, amount);
        callPlugins(false, from, to, amount);
    }

    // This function does 2 things, #1: it checks to make sure that the pledges are correct
    // if the a pledged project has already been commited then it changes the owner
    // to be the proposed project (Note that the UI will have to read the commit time and manually
    // do what this function does to the note for the end user at the expiration of the committime)
    // #2: It checks to make sure that if there has been a cancellation in the chain of projects,
    // then it adjusts the note's owner appropriately.
    // This call can be called from any body at any time on any node. In general it can be called
    // to froce the calls of the affected plugins.
    function normalizeNote(uint64 idNote) returns(uint64) {
        Note storage n = findNote(idNote);

        // Check to make sure this note hasnt already been used or is in the process of being used
        if (n.paymentState != PaymentState.NotPaid) return idNote;

        // First send to a project if it's proposed and commited
        if ((n.proposedProject > 0) && ( getTime() > n.commitTime)) {
            uint64 oldNote = findNote(
                n.owner,
                n.delegationChain,
                0,
                0,
                n.oldNote,
                PaymentState.NotPaid);
            uint64 toNote = findNote(
                n.proposedProject,
                new uint64[](0),
                0,
                0,
                oldNote,
                PaymentState.NotPaid);
            doTransfer(idNote, toNote, n.amount);
            idNote = toNote;
            n = findNote(idNote);
        }

        toNote = getOldestNoteNotCanceled(idNote);// TODO toNote is note defined
        if (toNote != idNote) {
            doTransfer(idNote, toNote, n.amount);
        }

        return toNote;
    }

/////////////
// Plugins
/////////////

    function callPlugin(bool before, uint64 managerId, uint64 fromNote, uint64 toNote, uint64 context, uint amount) internal returns (uint allowedAmount) {
        uint newAmount;
        allowedAmount = amount;
        NoteManager storage manager = findManager(managerId);
        if ((address(manager.plugin) != 0) && (allowedAmount > 0)) {
            if (before) {
                newAmount = manager.plugin.beforeTransfer(managerId, fromNote, toNote, context, amount);
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                manager.plugin.afterTransfer(managerId, fromNote, toNote, context, amount);
            }
        }
    }

    function callPluginsNote(bool before, uint64 idNote, uint64 fromNote, uint64 toNote, uint amount) internal returns (uint allowedAmount) {
        uint64 offset = idNote == fromNote ? 0 : 256;
        allowedAmount = amount;
        Note storage n = findNote(idNote);

        allowedAmount = callPlugin(before, n.owner, fromNote, toNote, offset, allowedAmount);

        for (uint64 i=0; i<n.delegationChain.length; i++) {
            allowedAmount = callPlugin(before, n.delegationChain[i], fromNote, toNote, offset + i+1, allowedAmount);
        }

        if (n.proposedProject > 0) {
            allowedAmount = callPlugin(before, n.proposedProject, fromNote, toNote, offset + 255, allowedAmount);
        }
    }

    function callPlugins(bool before, uint64 fromNote, uint64 toNote, uint amount) internal returns (uint allowedAmount) {
        allowedAmount = amount;

        allowedAmount = callPluginsNote(before, fromNote, fromNote, toNote, allowedAmount);
        allowedAmount = callPluginsNote(before, toNote, fromNote, toNote, allowedAmount);
    }

/////////////
// Test functions
/////////////

    function getTime() internal returns (uint) {
        return now;
    }

    event Transfer(uint64 indexed from, uint64 indexed to, uint amount);

}
