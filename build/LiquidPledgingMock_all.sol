
//File: contracts/ILiquidPledgingPlugin.sol
pragma solidity ^0.4.11;

contract ILiquidPledgingPlugin {

    /// @param context In which context it is affected.
    ///  0 -> owner from
    ///  1 -> First delegate from
    ///  2 -> Second delegate from
    ///  ...
    ///  255 -> proposedProject from
    ///
    ///  256 -> owner to
    ///  257 -> First delegate to
    ///  258 -> Second delegate to
    ///  ...
    ///  511 -> proposedProject to
    function beforeTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) returns (uint maxAllowed);
    function afterTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount);
}

//File: contracts/LiquidPledgingBase.sol
pragma solidity ^0.4.11;



contract Vault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

contract LiquidPledgingBase {

    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum NoteManagerType { Donor, Delegate, Project }// todo change name
    enum PaymentState { NotPaid, Paying, Paid }

    // This struct defines the details of each the NoteManager, these NoteManagers can create
    struct NoteManager {// change manager
        NoteManagerType managerType;
        address addr;
        string name;
        uint64 commitTime;  // Only used in donors and projects, its the precommitment time
        uint64 parentProject;  // Only for projects
        bool canceled;      // Only for project
        ILiquidPledgingPlugin plugin;     // Handler that is called when one call is affected.
    }

    struct Note {
        uint amount;
        uint64 owner;
        uint64[] delegationChain; //index numbers!!!!!
        uint64 proposedProject; // TODO change the name only used for when delegates are precommiting to a project
        uint64 commitTime;  // At what time the upcoming time will become an owner.
        uint64 oldNote; // this points to the Note[] index that the Note was derived from
        PaymentState paymentState;
    }

    Note[] notes;
    NoteManager[] managers; // the list of all the note managers 0 is reserved for no manager
    Vault public vault;

    // this mapping allows you to search for a specific note's index number by the hash of that note
    mapping (bytes32 => uint64) hNote2ddx;//TODO Fix typo


/////
// Modifiers
/////

    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }


//////
// Constructor
//////

    function LiquidPledgingBase(address _vault) {
        managers.length = 1; // we reserve the 0 manager
        notes.length = 1; // we reserve the 0 note
        vault = Vault(_vault);
    }


///////
// Managers functions
//////

    function addDonor(string name, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idDonor) {//Todo return idManager

        idDonor = uint64(managers.length);

        managers.push(NoteManager(
            NoteManagerType.Donor,
            msg.sender,
            name,
            commitTime,
            0,
            false,
            plugin));

        DonorAdded(idDonor);
    }

    event DonorAdded(uint64 indexed idDonor);

    function updateDonor(
        uint64 idDonor,
        address newAddr,
        string newName,
        uint64 newCommitTime)
    {
        NoteManager storage donor = findManager(idDonor);
        require(donor.managerType == NoteManagerType.Donor);
        require(donor.addr == msg.sender);
        donor.addr = newAddr;
        donor.name = newName;
        donor.commitTime = newCommitTime;
        DonorUpdated(idDonor);
    }

    event DonorUpdated(uint64 indexed idDonor);

    function addDelegate(string name, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idDelegate) { //TODO return index number

        idDelegate = uint64(managers.length);

        managers.push(NoteManager(
            NoteManagerType.Delegate,
            msg.sender,
            name,
            commitTime,
            0,
            false,
            plugin));

        DeegateAdded(idDelegate);
    }

    event DeegateAdded(uint64 indexed idDelegate);

    function updateDelegate(
        uint64 idDelegate,
        address newAddr,
        string newName,
        uint64 newCommitTime) {
        NoteManager storage delegate = findManager(idDelegate);
        require(delegate.managerType == NoteManagerType.Delegate);
        require(delegate.addr == msg.sender);
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint64 indexed idDelegate);

    function addProject(string name, address projectManager, uint64 parentProject, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idProject) {
        if (parentProject != 0) {
            NoteManager storage pm = findManager(parentProject);
            require(pm.managerType == NoteManagerType.Project);
            require(pm.addr == msg.sender);
            require(getProjectLevel(pm) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = uint64(managers.length);

        managers.push(NoteManager(
            NoteManagerType.Project,
            projectManager,
            name,
            commitTime,
            parentProject,
            false,
            plugin));


        ProjectAdded(idProject);
    }

    event ProjectAdded(uint64 indexed idProject);

    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        uint64 newCommitTime)
    {
        NoteManager storage project = findManager(idProject);
        require(project.managerType == NoteManagerType.Project);
        require(project.addr == msg.sender);
        project.addr = newAddr;
        project.name = newName;
        project.commitTime = newCommitTime;
        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint64 indexed idManager);


//////////
// Public constant functions
//////////


    function numberOfNotes() constant returns (uint) {
        return notes.length - 1;
    }

    function getNote(uint64 idNote) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 proposedProject,
        uint64 commitTime,
        uint64 oldNote,
        PaymentState paymentState
    ) {
        Note storage n = findNote(idNote);
        amount = n.amount;
        owner = n.owner;
        nDelegates = uint64(n.delegationChain.length);
        proposedProject = n.proposedProject;
        commitTime = n.commitTime;
        oldNote = n.oldNote;
        paymentState = n.paymentState;
    }
    // This is to return the delegates one by one, because you can not return an array
    function getNoteDelegate(uint64 idNote, uint idxDelegate) constant returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Note storage n = findNote(idNote);
        idDelegate = n.delegationChain[idxDelegate - 1];
        NoteManager storage delegate = findManager(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }

    function numberOfNoteManagers() constant returns(uint) {
        return managers.length - 1;
    }

    function getNoteManager(uint64 idManager) constant returns (
        NoteManagerType managerType,
        address addr,
        string name,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled)
    {
        NoteManager storage m = findManager(idManager);
        managerType = m.managerType;
        addr = m.addr;
        name = m.name;
        commitTime = m.commitTime;
        parentProject = m.parentProject;
        canceled = m.canceled;
    }

////////
// Private methods
///////

    // All notes exist... but if the note hasn't been created in this system yet then it wouldn't
    // be in the hash array hNoteddx[]
    // this function creates a balloon if one is not created already... this ballon has 0 for the amount
    function findNote(
        uint64 owner,
        uint64[] delegationChain,
        uint64 proposedProject,
        uint64 commitTime,
        uint64 oldNote,
        PaymentState paid
        ) internal returns (uint64)
    {
        bytes32 hNote = sha3(owner, delegationChain, proposedProject, commitTime, oldNote, paid);
        uint64 idx = hNote2ddx[hNote];
        if (idx > 0) return idx;
        idx = uint64(notes.length);
        hNote2ddx[hNote] = idx;
        notes.push(Note(0, owner, delegationChain, proposedProject, commitTime, oldNote, paid));
        return idx;
    }

    function findManager(uint64 idManager) internal returns (NoteManager storage) {
        require(idManager < managers.length);
        return managers[idManager];
    }

    function findNote(uint64 idNote) internal returns (Note storage) {
        require(idNote < notes.length);
        return notes[idNote];
    }

    // a constant for the case that a delegate is requested that is not a delegate in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    // helper function that searches the delegationChain fro a specific delegate and
    // level of delegation returns their idx in the delegation cahin which reflect their level of authority
    function getDelegateIdx(Note n, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    // helper function that returns the note level solely to check that transfers
    // between Projects not violate MAX_INTERPROJECT_LEVEL
    function getNoteLevel(Note n) internal returns(uint) {
        if (n.oldNote == 0) return 0;//changed
        Note storage oldN = findNote(n.oldNote);
        return getNoteLevel(oldN) + 1;
    }

    // helper function that returns the max commit time of the owner and all the
    // delegates
    function maxCommitTime(Note n) internal returns(uint commitTime) {
        NoteManager storage m = findManager(n.owner);
        commitTime = m.commitTime;

        for (uint i=0; i<n.delegationChain.length; i++) {
            m = findManager(n.delegationChain[i]);
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

    // helper function that returns the project level solely to check that there
    // are not too many Projects that violate MAX_SUBPROJECT_LEVEL
    function getProjectLevel(NoteManager m) internal returns(uint) {
        assert(m.managerType == NoteManagerType.Project);
        if (m.parentProject == 0) return(1);
        NoteManager storage parentNM = findManager(m.parentProject);
        return getProjectLevel(parentNM);
    }

    function isProjectCanceled(uint64 projectId) constant returns (bool) {
        NoteManager storage m = findManager(projectId);
        if (m.managerType == NoteManagerType.Donor) return false;
        assert(m.managerType == NoteManagerType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled(m.parentProject);
    }

    function isProjectCanceled2(uint64 projectId) constant returns (bool) {
        NoteManager storage m = findManager(projectId);
        return false;
        if (m.managerType == NoteManagerType.Donor) return false;
        assert(m.managerType == NoteManagerType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled2(m.parentProject);
    }

    // this makes it easy to cancel projects
    // @param idNote the note that may or may not be cancelled
    function getOldestNoteNotCanceled(uint64 idNote) internal constant returns(uint64) { //todo rename
        if (idNote == 0) return 0;
        Note storage n = findNote(idNote);
        NoteManager storage manager = findManager(n.owner);
        if (manager.managerType == NoteManagerType.Donor) return idNote;

        assert(manager.managerType == NoteManagerType.Project);

        if (!isProjectCanceled(n.owner)) return idNote;

        return getOldestNoteNotCanceled(n.oldNote);
    }

    function checkManagerOwner(NoteManager m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }




}

//File: contracts/LiquidPledging.sol
pragma solidity ^0.4.11;




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
    function normalizeNote(uint64 idNote) internal returns(uint64) {
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

//File: ./contracts/LiquidPledgingMock.sol
pragma solidity ^0.4.11;



// @dev LiquidPledgingMock mocks current block number

contract LiquidPledgingMock is LiquidPledging {

    uint public mock_time;

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
