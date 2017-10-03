
//File: contracts/ILiquidPledgingPlugin.sol
pragma solidity ^0.4.11;

contract ILiquidPledgingPlugin {
    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the proposedCampaign transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the proposedCampaign receiving pledge to another party
    function beforeTransfer(
        uint64 noteManager,
        uint64 noteFrom,
        uint64 noteTo,
        uint64 context,
        uint amount
        ) returns (uint maxAllowed);
    function afterTransfer(
        uint64 noteManager,
        uint64 noteFrom,
        uint64 noteTo,
        uint64 context,
        uint amount);
}

//File: contracts/LiquidPledgingBase.sol
pragma solidity ^0.4.11;



/// @dev This is declares a few functions from `Vault` so that the
///  `LiquidPledgingBase` contract can interface with the `Vault` contract
contract Vault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

contract LiquidPledgingBase {
    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBCAMPAIGN_LEVEL = 20;
    uint constant MAX_INTERCAMPAIGN_LEVEL = 20;

    enum NoteManagerType { Giver, Delegate, Campaign }
    enum PaymentState { NotPaid, Paying, Paid } // TODO name change NotPaid

    /// @dev This struct defines the details of each the NoteManager, these
    ///  NoteManagers can own notes and act as delegates
    struct NoteManager { // TODO name change NoteManager
        NoteManagerType managerType; // Giver, Delegate or Campaign
        address addr; // account or contract address for admin
        string name;
        uint64 commitTime;  // In seconds, used for Givers' & Delegates' vetos
        uint64 parentCampaign;  // Only for campaigns
        bool canceled;      //Always false except for canceled campaigns
        ILiquidPledgingPlugin plugin; // if the plugin is 0x0 then nothing happens if its a contract address than that smart contract is called via the milestone contract
    }

    struct Note {
        uint amount;
        uint64 owner; //NoteManager
        uint64[] delegationChain; // list of index numbers
        uint64 proposedCampaign; // TODO change the name only used for when delegates are precommiting to a campaign
        uint64 commitTime;  // When the proposedCampaign will become the owner
        uint64 oldNote; // this points to the Note[] index that the Note was derived from
        PaymentState paymentState;
    }

    Note[] notes;
    NoteManager[] managers; //The list of noteManagers 0 means there is no manager
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

    /// @notice The Constructor creates the `LiquidPledgingBase` on the blockchain
    /// @param _vault Where the ETH is stored that the pledges represent
    function LiquidPledgingBase(address _vault) {
        managers.length = 1; // we reserve the 0 manager
        notes.length = 1; // we reserve the 0 note
        vault = Vault(_vault);
    }


///////
// Managers functions
//////

    /// @notice Creates a giver.
    function addGiver(string name, uint64 commitTime, ILiquidPledgingPlugin plugin
        ) returns (uint64 idGiver) {

        idGiver = uint64(managers.length);

        managers.push(NoteManager(
            NoteManagerType.Giver,
            msg.sender,
            name,
            commitTime,
            0,
            false,
            plugin));

        GiverAdded(idGiver);
    }

    event GiverAdded(uint64 indexed idGiver);

    ///@notice Changes the address, name or commitTime associated with a specific giver
    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        uint64 newCommitTime)
    {
        NoteManager storage giver = findManager(idGiver);
        require(giver.managerType == NoteManagerType.Giver);//Must be a Giver
        require(giver.addr == msg.sender);//current addr had to originate this tx
        giver.addr = newAddr;
        giver.name = newName;
        giver.commitTime = newCommitTime;
        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint64 indexed idGiver);

    /// @notice Creates a new Delegate
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

        DelegateAdded(idDelegate);
    }

    event DelegateAdded(uint64 indexed idDelegate);

    ///@notice Changes the address, name or commitTime associated with a specific delegate
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

    /// @notice Creates a new Campaign
    function addCampaign(string name, address campaignManager, uint64 parentCampaign, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idCampaign) {
        if (parentCampaign != 0) {
            NoteManager storage pm = findManager(parentCampaign);
            require(pm.managerType == NoteManagerType.Campaign);
            require(pm.addr == msg.sender);
            require(getCampaignLevel(pm) < MAX_SUBCAMPAIGN_LEVEL);
        }

        idCampaign = uint64(managers.length);

        managers.push(NoteManager(
            NoteManagerType.Campaign,
            campaignManager,
            name,
            commitTime,
            parentCampaign,
            false,
            plugin));


        CampaignAdded(idCampaign);
    }

    event CampaignAdded(uint64 indexed idCampaign);

    ///@notice Changes the address, name or commitTime associated with a specific Campaign
    function updateCampaign(
        uint64 idCampaign,
        address newAddr,
        string newName,
        uint64 newCommitTime)
    {
        NoteManager storage campaign = findManager(idCampaign);
        require(campaign.managerType == NoteManagerType.Campaign);
        require(campaign.addr == msg.sender);
        campaign.addr = newAddr;
        campaign.name = newName;
        campaign.commitTime = newCommitTime;
        CampaignUpdated(idCampaign);
    }

    event CampaignUpdated(uint64 indexed idManager);


//////////
// Public constant functions
//////////

    /// @notice Public constant that states how many notes are in the system
    function numberOfNotes() constant returns (uint) {
        return notes.length - 1;
    }
    /// @notice Public constant that states the details of the specified Note
    function getNote(uint64 idNote) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 proposedCampaign,
        uint64 commitTime,
        uint64 oldNote,
        PaymentState paymentState
    ) {
        Note storage n = findNote(idNote);
        amount = n.amount;
        owner = n.owner;
        nDelegates = uint64(n.delegationChain.length);
        proposedCampaign = n.proposedCampaign;
        commitTime = n.commitTime;
        oldNote = n.oldNote;
        paymentState = n.paymentState;
    }
    /// @notice Public constant that states the delegates one by one, because
    ///  an array cannot be returned
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
    /// @notice Public constant that states the number of admins in the system
    function numberOfNoteManagers() constant returns(uint) {
        return managers.length - 1;
    }
    /// @notice Public constant that states the details of the specified admin
    function getNoteManager(uint64 idManager) constant returns (
        NoteManagerType managerType,
        address addr,
        string name,
        uint64 commitTime,
        uint64 parentCampaign,
        bool canceled,
        address plugin)
    {
        NoteManager storage m = findManager(idManager);
        managerType = m.managerType;
        addr = m.addr;
        name = m.name;
        commitTime = m.commitTime;
        parentCampaign = m.parentCampaign;
        canceled = m.canceled;
        plugin = address(m.plugin);
    }

////////
// Private methods
///////

    /// @notice All notes technically exist... but if the note hasn't been
    ///  created in this system yet then it wouldn't be in the hash array
    ///  hNoteddx[]; this creates a Pledge with and amount of 0 if one is not
    ///  created already...
    function findNote(
        uint64 owner,
        uint64[] delegationChain,
        uint64 proposedCampaign,
        uint64 commitTime,
        uint64 oldNote,
        PaymentState paid
        ) internal returns (uint64)
    {
        bytes32 hNote = sha3(owner, delegationChain, proposedCampaign, commitTime, oldNote, paid);
        uint64 idx = hNote2ddx[hNote];
        if (idx > 0) return idx;
        idx = uint64(notes.length);
        hNote2ddx[hNote] = idx;
        notes.push(Note(0, owner, delegationChain, proposedCampaign, commitTime, oldNote, paid));
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
    // level of delegation returns their idx in the delegation chain which reflect their level of authority
    function getDelegateIdx(Note n, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    // helper function that returns the note level solely to check that transfers
    // between Campaigns not violate MAX_INTERCAMPAIGN_LEVEL
    function getNoteLevel(Note n) internal returns(uint) {
        if (n.oldNote == 0) return 0; //changed
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

    // helper function that returns the campaign level solely to check that there
    // are not too many Campaigns that violate MAX_SUBCAMPAIGNS_LEVEL
    function getCampaignLevel(NoteManager m) internal returns(uint) {
        assert(m.managerType == NoteManagerType.Campaign);
        if (m.parentCampaign == 0) return(1);
        NoteManager storage parentNM = findManager(m.parentCampaign);
        return getCampaignLevel(parentNM);
    }

    function isCampaignCanceled(uint64 campaignId) constant returns (bool) {
        NoteManager storage m = findManager(campaignId);
        if (m.managerType == NoteManagerType.Giver) return false;
        assert(m.managerType == NoteManagerType.Campaign);
        if (m.canceled) return true;
        if (m.parentCampaign == 0) return false;
        return isCampaignCanceled(m.parentCampaign);
    }

    // @notice A helper function for canceling campaigns
    // @param idNote the note that may or may not be canceled
    function getOldestNoteNotCanceled(uint64 idNote) internal constant returns(uint64) { //todo rename
        if (idNote == 0) return 0;
        Note storage n = findNote(idNote);
        NoteManager storage manager = findManager(n.owner);
        if (manager.managerType == NoteManagerType.Giver) return idNote;

        assert(manager.managerType == NoteManagerType.Campaign);

        if (!isCampaignCanceled(n.owner)) return idNote;

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

    // This constructor  also calls the constructor for `LiquidPledgingBase`
    function LiquidPledging(address _vault) LiquidPledgingBase(_vault) {
    }

    /// @notice This is how value enters into the system which creates pledges;
    ///  the token of value goes into the vault and the amount in the pledge
    ///  relevant to this Giver without delegates is increased, and a normal
    ///  transfer is done to the idReceiver
    /// @param idGiver Identifier of the giver thats donating.
    /// @param idReceiver To whom it's transfered. Can be the same giver, another
    ///  giver, a delegate or a campaign

function donate(uint64 idGiver, uint64 idReceiver) payable {
        if (idGiver == 0) {
            idGiver = addGiver('', 259200, ILiquidPledgingPlugin(0x0)); // default to 3 day commitTime
        }

        NoteManager storage sender = findManager(idGiver);

        checkManagerOwner(sender);

        require(sender.managerType == NoteManagerType.Giver);

        uint amount = msg.value;

        require(amount > 0);

        vault.transfer(amount); // transfers the baseToken to the Vault
        uint64 idNote = findNote(
            idGiver,
            new uint64[](0), //what is new?
            0,
            0,
            0,
            PaymentState.NotPaid);


        Note storage nTo = findNote(idNote);
        nTo.amount += amount;

        Transfer(0, idNote, amount);

        transfer(idGiver, idNote, amount, idReceiver);
    }


    /// @notice Moves value between notes
    /// @param idSender ID of the giver, delegate or campaign manager that is transferring
    ///  the funds from Note to Note. This manager must have permissions to move the value
    /// @param idNote Id of the note that's moving the value
    /// @param amount Quantity of value that's being moved
    /// @param idReceiver Destination of the value, can be a giver sending to a giver or
    ///  a delegate, a delegate to another delegate or a campaign to precommit it to that campaign
    function transfer(uint64 idSender, uint64 idNote, uint amount, uint64 idReceiver) {

        idNote = normalizeNote(idNote);

        Note storage n = findNote(idNote);
        NoteManager storage receiver = findManager(idReceiver);
        NoteManager storage sender = findManager(idSender);

        checkManagerOwner(sender);
        require(n.paymentState == PaymentState.NotPaid);

        // If the sender is the owner
        if (n.owner == idSender) {
            if (receiver.managerType == NoteManagerType.Giver) {
                transferOwnershipToGiver(idNote, amount, idReceiver);
            } else if (receiver.managerType == NoteManagerType.Campaign) {
                transferOwnershipToCampaign(idNote, amount, idReceiver);
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

            // If the receiver is another giver
            if (receiver.managerType == NoteManagerType.Giver) {
                // Only accept to change to the original giver to remove all delegates
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

            // If the delegate wants to support a campaign, they undelegate all
            // the delegates after them in the chain and choose a campaign
            if (receiver.managerType == NoteManagerType.Campaign) {
                undelegate(idNote, amount, n.delegationChain.length - senderDIdx - 1);
                proposeAssignCampaign(idNote, amount, idReceiver);
                return;
            }
        }
        assert(false);  // It is not the owner nor any delegate.
    }


    /// @notice This method is used to withdraw value from the system. This can be used
    ///  by the givers to avoid committing the donation or by campaign manager to use
    ///  the Ether.
    /// @param idNote Id of the note that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
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
    /// @param idNote Id of the note that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
    function confirmPayment(uint64 idNote, uint amount) onlyVault {
        Note storage n = findNote(idNote);

        require(n.paymentState == PaymentState.Paying);

        // Check the campaign is not canceled in the while.
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

        // When a payment is canceled, never is assigned to a campaign.
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

    /// @notice Method called to cancel this campaign.
    /// @param idCampaign Id of the projct that wants to be canceled.
    function cancelCampaign(uint64 idCampaign) {
        NoteManager storage campaign = findManager(idCampaign);
        checkManagerOwner(campaign);
        campaign.canceled = true;

        CancelCampaign(idCampaign);
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
    // by setting yourself as the idReceiver
    function transferOwnershipToCampaign(uint64 idNote, uint amount, uint64 idReceiver) internal  {
        Note storage n = findNote(idNote);

        require(getNoteLevel(n) < MAX_INTERCAMPAIGN_LEVEL);
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

    function transferOwnershipToGiver(uint64 idNote, uint amount, uint64 idReceiver) internal  {
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

    /// @param q Number of undelegations
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


    function proposeAssignCampaign(uint64 idNote, uint amount, uint64 idReceiver) internal {// Todo rename
        Note storage n = findNote(idNote);

        require(getNoteLevel(n) < MAX_SUBCAMPAIGN_LEVEL);

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
    // if the a pledged campaign has already been committed then it changes the owner
    // to be the proposed campaign (Note that the UI will have to read the commit time and manually
    // do what this function does to the note for the end user at the expiration of the commitTime)
    // #2: It checks to make sure that if there has been a cancellation in the chain of campaigns,
    // then it adjusts the note's owner appropriately.
    // This call can be called from any body at any time on any node. In general it can be called
    // to force the calls of the affected plugins, which also need to be predicted by the UI
    function normalizeNote(uint64 idNote) returns(uint64) {
        Note storage n = findNote(idNote);

        // Check to make sure this note hasnt already been used or is in the process of being used
        if (n.paymentState != PaymentState.NotPaid) return idNote;

        // First send to a campaign if it's proposed and commited
        if ((n.proposedCampaign > 0) && ( getTime() > n.commitTime)) {
            uint64 oldNote = findNote(
                n.owner,
                n.delegationChain,
                0,
                0,
                n.oldNote,
                PaymentState.NotPaid);
            uint64 toNote = findNote(
                n.proposedCampaign,
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

        if (n.proposedCampaign > 0) {
            allowedAmount = callPlugin(before, n.proposedCampaign, fromNote, toNote, offset + 255, allowedAmount);
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
    event CancelCampaign(uint64 indexed idCampaign);

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
