pragma solidity ^0.4.11;

contract Vault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
}

contract LiquidPledgingBase {

    enum NoteManagerType { Donor, Delegate, Project }
    enum PaymentState {NotPaid, Paying, Paid}

    struct NoteManager {
        NoteManagerType managerType;
        address addr;
        string name;
        uint64 commitTime;  // Only used in donors and campaigns
        address reviewer;  // Only for project
        bool canceled;      // Only for project
    }

    struct Note {
        uint amount;
        uint64 owner;
        uint64[] delegationChain;
        uint64 proposedProject;
        uint64 commitTime;  // At what time the upcoming time will become an owner.
        uint64 oldNote;
        PaymentState paymentState;
    }

    Note[] notes;
    NoteManager[] managers;
    Vault public vault;


    mapping (bytes32 => uint64) hNote2ddx;


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
        managers.length = 1;
        notes.length = 1;
        vault = Vault(_vault);
    }


///////
// Managers functions
//////

    function addDonor(string name, uint64 commitTime) {
        managers.push(NoteManager(
            NoteManagerType.Donor,
            msg.sender,
            name,
            commitTime,
            0x0,
            false));

        DonorAdded(uint64(managers.length-1));
    }

    event DonorAdded(uint64 indexed idMember);

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

    event DonorUpdated(uint64 indexed idMember);

    function addDelegate(string name) {
        managers.push(NoteManager(
            NoteManagerType.Delegate,
            msg.sender,
            name,
            0,
            0x0,
            false));

        DeegateAdded(uint64(managers.length-1));
    }

    event DeegateAdded(uint64 indexed idMember);

    function updateDelegate(uint64 idDelegate, address newAddr, string newName) {
        NoteManager storage delegate = findManager(idDelegate);
        require(delegate.managerType == NoteManagerType.Delegate);
        require(delegate.addr == msg.sender);
        delegate.addr = newAddr;
        delegate.name = newName;
        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint64 indexed idMember);

    function addProject(string name, address reviewer, uint64 commitTime) {
        managers.push(NoteManager(
            NoteManagerType.Project,
            msg.sender,
            name,
            commitTime,
            reviewer,
            false));

        ProjectAdded(uint64(managers.length-1));
    }

    event ProjectAdded(uint64 indexed idMember);

    function updateProject(uint64 idProject, address newAddr, string newName, uint64 newCommitTime) {
        NoteManager storage project = findManager(idProject);
        require(project.managerType == NoteManagerType.Project);
        require(project.addr == msg.sender);
        project.addr = newAddr;
        project.name = newName;
        project.commitTime = newCommitTime;
        ProjectUpdated(idProject);
    }

    function updateProjectCanceler(uint64 idProject, address newReviewer) {
        NoteManager storage project = findManager(idProject);
        require(project.managerType == NoteManagerType.Project);
        require(project.reviewer == msg.sender);
        project.reviewer = newReviewer;
        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint64 indexed idMember);


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
        address reviewer,
        bool canceled)
    {
        NoteManager storage m = findManager(idManager);
        managerType = m.managerType;
        addr = m.addr;
        name = m.name;
        commitTime = m.commitTime;
        reviewer = m.reviewer;
        canceled = m.canceled;
    }

////////
// Private methods
///////

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

    function getOldestNoteNotCanceled(uint64 idNote) internal constant returns(uint64) {
        if (idNote == 0) return 0;
        Note storage n = findNote(idNote);
        NoteManager storage owner = findManager(n.owner);
        if (owner.managerType == NoteManagerType.Donor) return idNote;

        uint64 parentProject = getOldestNoteNotCanceled(n.oldNote);

        if (owner.canceled) {    // Current project is canceled.
            return parentProject;
        } else if (parentProject == n.oldNote) {   // None of the top projects is canceled
            return idNote;
        } else {                        // Current is not canceled but some ont the top yes
            return parentProject;
        }
    }

    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;
    function getDelegateIdx(Note n, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    function getProjectLevel(Note n) internal returns(uint) {
        if (n.oldNote == 0) return 1;
        Note storage oldN = findNote(n.oldNote);
        return getProjectLevel(oldN) + 1;
    }

}
