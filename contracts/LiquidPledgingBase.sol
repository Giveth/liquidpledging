pragma solidity ^0.4.11;

import "./ILiquidPledgingPlugin.sol";

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
        bool canceled,
        address plugin)
    {
        NoteManager storage m = findManager(idManager);
        managerType = m.managerType;
        addr = m.addr;
        name = m.name;
        commitTime = m.commitTime;
        parentProject = m.parentProject;
        canceled = m.canceled;
        plugin = address(m.plugin);
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
