
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
    ///  255 -> Plugin for the intendedCampaign transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedCampaign receiving pledge to another party
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

//File: ./contracts/LiquidPledgingBase.sol
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

    enum PledgeAdminType { Giver, Delegate, Campaign }
    enum PaymentState { Pledged, Paying, Paid } // TODO name change Pledged

    /// @dev This struct defines the details of each the PledgeAdmin, these
    ///  PledgeAdmins can own pledges and act as delegates
    struct PledgeAdmin { // TODO name change PledgeAdmin
        PledgeAdminType adminType; // Giver, Delegate or Campaign
        address addr; // account or contract address for admin
        string name;
        string url;
        uint64 commitTime;  // In seconds, used for Givers' & Delegates' vetos
        uint64 parentCampaign;  // Only for campaigns
        bool canceled;      //Always false except for canceled campaigns
        ILiquidPledgingPlugin plugin; // if the plugin is 0x0 then nothing happens if its a contract address than that smart contract is called via the milestone contract
    }

    struct Pledge {
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // list of index numbers
        uint64 intendedCampaign; // TODO change the name only used for when delegates are precommiting to a campaign
        uint64 commitTime;  // When the intendedCampaign will become the owner
        uint64 oldPledge; // this points to the Pledge[] index that the Pledge was derived from
        PaymentState paymentState;
    }

    Pledge[] pledges;
    PledgeAdmin[] admins; //The list of pledgeAdmins 0 means there is no admin
    Vault public vault;

    // this mapping allows you to search for a specific pledge's index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;//TODO Fix typo


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
        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
        vault = Vault(_vault);
    }


///////
// Adminss functions
//////

    /// @notice Creates a giver.
    function addGiver(string name, string url, uint64 commitTime, ILiquidPledgingPlugin plugin
        ) returns (uint64 idGiver) {

        idGiver = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Giver,
            msg.sender,
            name,
            url,
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
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage giver = findAdmin(idGiver);
        require(giver.adminType == PledgeAdminType.Giver); //Must be a Giver
        require(giver.addr == msg.sender); //current addr had to originate this tx
        giver.addr = newAddr;
        giver.name = newName;
        giver.url = newUrl;
        giver.commitTime = newCommitTime;
        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint64 indexed idGiver);

    /// @notice Creates a new Delegate
    function addDelegate(string name, string url, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idDelegate) { //TODO return index number

        idDelegate = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Delegate,
            msg.sender,
            name,
            url,
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
        string newUrl,
        uint64 newCommitTime) {
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        require(delegate.adminType == PledgeAdminType.Delegate);
        require(delegate.addr == msg.sender);
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint64 indexed idDelegate);

    /// @notice Creates a new Campaign
    function addCampaign(string name, string url, address campaignAdmin, uint64 parentCampaign, uint64 commitTime, ILiquidPledgingPlugin plugin) returns (uint64 idCampaign) {
        if (parentCampaign != 0) {
            PledgeAdmin storage pm = findAdmin(parentCampaign);
            require(pm.adminType == PledgeAdminType.Campaign);
            require(pm.addr == msg.sender);
            require(getCampaignLevel(pm) < MAX_SUBCAMPAIGN_LEVEL);
        }

        idCampaign = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Campaign,
            campaignAdmin,
            name,
            url,
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
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage campaign = findAdmin(idCampaign);
        require(campaign.adminType == PledgeAdminType.Campaign);
        require(campaign.addr == msg.sender);
        campaign.addr = newAddr;
        campaign.name = newName;
        campaign.url = newUrl;
        campaign.commitTime = newCommitTime;
        CampaignUpdated(idCampaign);
    }

    event CampaignUpdated(uint64 indexed idAdmin);


//////////
// Public constant functions
//////////

    /// @notice Public constant that states how many pledgess are in the system
    function numberOfPledges() constant returns (uint) {
        return pledges.length - 1;
    }
    /// @notice Public constant that states the details of the specified Pledge
    function getPledge(uint64 idPledge) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedCampaign,
        uint64 commitTime,
        uint64 oldPledge,
        PaymentState paymentState
    ) {
        Pledge storage n = findPledge(idPledge);
        amount = n.amount;
        owner = n.owner;
        nDelegates = uint64(n.delegationChain.length);
        intendedCampaign = n.intendedCampaign;
        commitTime = n.commitTime;
        oldPledge = n.oldPledge;
        paymentState = n.paymentState;
    }
    /// @notice Public constant that states the delegates one by one, because
    ///  an array cannot be returned
    function getPledgeDelegate(uint64 idPledge, uint idxDelegate) constant returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage n = findPledge(idPledge);
        idDelegate = n.delegationChain[idxDelegate - 1];
        PledgeAdmin storage delegate = findAdmin(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }
    /// @notice Public constant that states the number of admins in the system
    function numberOfPledgeAdmins() constant returns(uint) {
        return admins.length - 1;
    }
    /// @notice Public constant that states the details of the specified admin
    function getPledgeAdmin(uint64 idAdmin) constant returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentCampaign,
        bool canceled,
        address plugin)
    {
        PledgeAdmin storage m = findAdmin(idAdmin);
        adminType = m.adminType;
        addr = m.addr;
        name = m.name;
        url = m.url;
        commitTime = m.commitTime;
        parentCampaign = m.parentCampaign;
        canceled = m.canceled;
        plugin = address(m.plugin);
    }

////////
// Private methods
///////

    /// @notice All pledges technically exist... but if the pledge hasn't been
    ///  created in this system yet then it wouldn't be in the hash array
    ///  hPledge2idx[]; this creates a Pledge with and amount of 0 if one is not
    ///  created already...
    function findPledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedCampaign,
        uint64 commitTime,
        uint64 oldPledge,
        PaymentState paid
        ) internal returns (uint64)
    {
        bytes32 hPledge = sha3(owner, delegationChain, intendedCampaign, commitTime, oldPledge, paid);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(0, owner, delegationChain, intendedCampaign, commitTime, oldPledge, paid));
        return idx;
    }

    function findAdmin(uint64 idAdmin) internal returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

    function findPledge(uint64 idPledge) internal returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    // a constant for the case that a delegate is requested that is not a delegate in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    // helper function that searches the delegationChain fro a specific delegate and
    // level of delegation returns their idx in the delegation chain which reflect their level of authority
    function getDelegateIdx(Pledge n, uint64 idDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    // helper function that returns the pledge level solely to check that transfers
    // between Campaigns not violate MAX_INTERCAMPAIGN_LEVEL
    function getPledgeLevel(Pledge n) internal returns(uint) {
        if (n.oldPledge == 0) return 0; //changed
        Pledge storage oldN = findPledge(n.oldPledge);
        return getPledgeLevel(oldN) + 1;
    }

    // helper function that returns the max commit time of the owner and all the
    // delegates
    function maxCommitTime(Pledge n) internal returns(uint commitTime) {
        PledgeAdmin storage m = findAdmin(n.owner);
        commitTime = m.commitTime;

        for (uint i=0; i<n.delegationChain.length; i++) {
            m = findAdmin(n.delegationChain[i]);
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

    // helper function that returns the campaign level solely to check that there
    // are not too many Campaigns that violate MAX_SUBCAMPAIGNS_LEVEL
    function getCampaignLevel(PledgeAdmin m) internal returns(uint) {
        assert(m.adminType == PledgeAdminType.Campaign);
        if (m.parentCampaign == 0) return(1);
        PledgeAdmin storage parentNM = findAdmin(m.parentCampaign);
        return getCampaignLevel(parentNM);
    }

    function isCampaignCanceled(uint64 campaignId) constant returns (bool) {
        PledgeAdmin storage m = findAdmin(campaignId);
        if (m.adminType == PledgeAdminType.Giver) return false;
        assert(m.adminType == PledgeAdminType.Campaign);
        if (m.canceled) return true;
        if (m.parentCampaign == 0) return false;
        return isCampaignCanceled(m.parentCampaign);
    }

    // @notice A helper function for canceling campaigns
    // @param idPledge the pledge that may or may not be canceled
    function getOldestPledgeNotCanceled(uint64 idPledge) internal constant returns(uint64) { //todo rename
        if (idPledge == 0) return 0;
        Pledge storage n = findPledge(idPledge);
        PledgeAdmin storage admin = findAdmin(n.owner);
        if (admin.adminType == PledgeAdminType.Giver) return idPledge;

        assert(admin.adminType == PledgeAdminType.Campaign);

        if (!isCampaignCanceled(n.owner)) return idPledge;

        return getOldestPledgeNotCanceled(n.oldPledge);
    }

    function checkAdminOwner(PledgeAdmin m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }
}
