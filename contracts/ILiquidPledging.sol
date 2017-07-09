pragma solidity ^0.4.11;

contract ILiquidPledging {

// TODO: make this enum its own contract... or at least make it so that an owner
// can add a new NoteManagerType 
    enum NoteManagerType { Donor, Delegate, Project}
    enum PaymentState {NotPaid, Paying, Paid}

    function numberOfNotes() constant returns (uint);

    function getNote(uint64 idNote) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 proposedProject,
        uint64 commmitTime,
        uint64 oldNote,
        PaymentState paymentState
    );

    function getNoteDelegate(uint64 idNote, uint idxDelegate) constant returns(
        uint64 idDelegate,
        address addr,
        string name
    );


    function numberOfNoteManagers() constant returns(uint);

    function getNoteManager(uint64 idManager) constant returns (
        NoteManagerType managerType,
        address addr,
        string name,
        uint64 commitTime,
        address reviewer,
        bool canceled);

    event DonorAdded(uint64 indexed idMember);

    function addDonor(string name, uint64 commitTime);
    function updateDonor(
        uint64 idDonor,
        address newAddr,
        string newName,
        uint64 newCommitTime);

    function addDelegate(string name);
    function updateDelegate(uint64 idDelegate, address newAddr, string newName);

    function addProject(string name, address canceler, uint64 commitTime) ;
    function updateProject(uint64 idProject, address newAddr, string newName, uint64 newCommitTime);
    function updateProjectCanceler(uint64 idProject, address newCanceler);

    function donate(uint64 idDonor, uint64 idReceiver) payable;

    /// @param idSender idDonor or idDelegate that executes the action
    /// @param idReceiver idDonor or idCampaign that wants to be transfered.
    /// @param note piece That wants to be transfered.
    /// @param amount quantity of the state that wants to be transfered.
    function transfer(uint64 idSender, uint64 note, uint amount, uint64 idReceiver);
    function mTransfer(uint64 idSender, uint[] notesAmounts, uint64 idReceiver);

    function withdraw(uint64 note, uint amount, string concept);
    function mWithdraw(uint[] notesAmounts, string concept);

    function confirmPayment(uint64 idNote, uint amount);
    function mConfirmPayment(uint[] notesAmounts);

    function cancelPayment(uint64 idNote, uint amount);
    function mCancelPayment(uint[] notesAmounts);

    function cancelProject(int64 idCampaign);
}
