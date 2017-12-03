pragma solidity ^0.4.11;
/*
    Copyright 2017, Jordi Baylina
    Contributor: Adrià Massanet <adria@codecontext.io>

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
import "../node_modules/giveth-common-contracts/contracts/Owned.sol";

/// @dev `LPVault` serves as an interface to allow the `LiquidPledgingBase`
///  contract to interface with a `LPVault` contract
contract LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquid pledging's most basic functions, mostly handling and searching  the
///  data structures
contract LiquidPledgingBase is Owned {

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum PledgeAdminType { Giver, Delegate, Project }
    enum PaymentState { Pledged, Paying, Paid }

    /// @dev This struct defines the details of a `PledgeAdmin` which are 
    ///  commonly referenced by their index in the `admins` array.
    ///  and can own pledges and act as delegates
    struct PledgeAdmin { 
        PledgeAdminType adminType; // Giver, Delegate or Project
        address addr; // Account or contract address for admin
        string name;
        string url;  // Can be IPFS hash
        uint64 commitTime;  // In seconds, used for Givers' & Delegates' vetos
        uint64 parentProject;  // Only for projects
        bool canceled;      //Always false except for canceled projects

        /// @dev if the plugin is 0x0 then nothing happens, if its an address
        // than that smart contract is called when appropriate
        ILiquidPledgingPlugin plugin; 
    }

    struct Pledge {
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner  
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        PaymentState paymentState; //  Pledged, Paying, Paid 
    }

    Pledge[] pledges;
    PledgeAdmin[] admins; //The list of pledgeAdmins 0 means there is no admin
    LPVault public vault;

    /// @dev this mapping allows you to search for a specific pledge's 
    ///  index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;
    mapping (bytes32 => bool) pluginWhitelist;
    
    bool public usePluginWhitelist = true;

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
    function LiquidPledgingBase(address _vault) {
        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
        vault = LPVault(_vault); // Assigns the specified vault
    }


/////////////////////////
// PledgeAdmin functions
/////////////////////////

    /// @notice Creates a Giver Admin with the `msg.sender` as the Admin address
    /// @param name The name used to identify the Giver
    /// @param url The link to the Giver's profile often an IPFS hash
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param plugin This is Giver's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idGiver The id number used to reference this Admin
    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idGiver) {

        require(isValidPlugin(plugin)); // Plugin check

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

    /// @notice Updates a Giver's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Giver
    /// @param idGiver This is the Admin id number used to specify the Giver
    /// @param newAddr The new address that represents this Giver
    /// @param newName The new name used to identify the Giver
    /// @param newUrl The new link to the Giver's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage giver = findAdmin(idGiver);
        require(giver.adminType == PledgeAdminType.Giver); // Must be a Giver
        require(giver.addr == msg.sender); // Current addr had to send this tx
        giver.addr = newAddr;
        giver.name = newName;
        giver.url = newUrl;
        giver.commitTime = newCommitTime;
        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint64 indexed idGiver);

    /// @notice Creates a Delegate Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Delegate
    /// @param url The link to the Delegate's profile often an IPFS hash
    /// @param commitTime Sets the length of time in seconds that this delegate
    ///  can be vetoed. Whenever this delegate is in a delegate chain the time
    ///  allowed to veto any event must be greater than or equal to this time.
    /// @param plugin This is Delegate's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idxDelegate The id number used to reference this Delegate within
    ///  the admins array
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idxDelegate) { 

        require(isValidPlugin(plugin)); // Plugin check

        idxDelegate = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Delegate,
            msg.sender,
            name,
            url,
            commitTime,
            0,
            false,
            plugin));

        DelegateAdded(idxDelegate);
    }

    event DelegateAdded(uint64 indexed idxDelegate);

    /// @notice Updates a Delegate's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Delegate
    /// @param idxDelegate The Admin id number used to specify the Delegate
    /// @param newAddr The new address that represents this Delegate
    /// @param newName The new name used to identify the Delegate
    /// @param newUrl The new link to the Delegate's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds that this 
    ///  delegate can be vetoed. Whenever this delegate is in a delegate chain 
    ///  the time allowed to veto any event must be greater than or equal to
    ///  this time.
    function updateDelegate(
        uint64 idxDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime) {
        PledgeAdmin storage delegate = findAdmin(idxDelegate);
        require(delegate.adminType == PledgeAdminType.Delegate);
        require(delegate.addr == msg.sender);// Current addr had to send this tx
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idxDelegate);
    }

    event DelegateUpdated(uint64 indexed idxDelegate);

    /// @notice Creates a Project Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Project
    /// @param url The link to the Project's profile often an IPFS hash
    /// @param projectAdmin The address for the trusted project manager 
    /// @param parentProject The Admin id number for the parent project or 0 if
    ///  there is no parentProject
    /// @param commitTime Sets the length of time in seconds the Project has to
    ///   veto when the Project delegates to another Delegate and they pledge 
    ///   those funds to a project
    /// @param plugin This is Project's liquid pledge plugin allowing for 
    ///  extended functionality
    /// @return idProject The id number used to reference this Admin
    function addProject(
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idProject) {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            PledgeAdmin storage pa = findAdmin(parentProject);
            require(pa.adminType == PledgeAdminType.Project);
            require(getProjectLevel(pa) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = uint64(admins.length);

        admins.push(PledgeAdmin(
            PledgeAdminType.Project,
            projectAdmin,
            name,
            url,
            commitTime,
            parentProject,
            false,
            plugin));


        ProjectAdded(idProject);
    }

    event ProjectAdded(uint64 indexed idProject);


    /// @notice Updates a Project's info to change the address, name, url, or 
    ///  commitTime, it cannot be used to change a plugin or a parentProject,
    ///  and it must be called by the current address of the Project
    /// @param idProject The Admin id number used to specify the Project
    /// @param newAddr The new address that represents this Project
    /// @param newName The new name used to identify the Project
    /// @param newUrl The new link to the Project's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Project has
    ///  to veto when the Project delegates to a Delegate and they pledge those
    ///  funds to a project
    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime)
    {
        PledgeAdmin storage project = findAdmin(idProject);
        require(project.adminType == PledgeAdminType.Project);
        require(project.addr == msg.sender);
        project.addr = newAddr;
        project.name = newName;
        project.url = newUrl;
        project.commitTime = newCommitTime;
        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint64 indexed idAdmin);


//////////
// Public constant functions
//////////

    /// @notice A constant getter that returns the total number of pledges
    /// @return The total number of Pledges in the system
    function numberOfPledges() constant returns (uint) {
        return pledges.length - 1;
    }

    /// @notice A getter that returns the details of the specified pledge
    /// @param idPledge the id number of the pledge being queried
    /// @return the amount, owner, the number of delegates (but not the actual
    ///  delegates, the intendedProject (if any), the current commit time and
    ///  the previous pledge this pledge was derived from
    function getPledge(uint64 idPledge) constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PaymentState paymentState
    ) {
        Pledge storage n = findPledge(idPledge);
        amount = n.amount;
        owner = n.owner;
        nDelegates = uint64(n.delegationChain.length);
        intendedProject = n.intendedProject;
        commitTime = n.commitTime;
        oldPledge = n.oldPledge;
        paymentState = n.paymentState;
    }

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
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

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
    function numberOfPledgeAdmins() constant returns(uint) {
        return admins.length - 1;
    }

    /// @notice A constant getter to check the details of a specified Admin  
    /// @return addr Account or contract address for admin
    /// @return name Name of the pledgeAdmin
    /// @return url The link to the Project's profile often an IPFS hash
    /// @return commitTime The length of time in seconds the Admin has to veto
    ///   when the Admin delegates to a Delegate and that Delegate pledges those
    ///   funds to a project
    /// @return parentProject The Admin id number for the parent project or 0
    ///  if there is no parentProject
    /// @return canceled 0 for Delegates & Givers, true if a Project has been 
    ///  canceled
    /// @return plugin This is Project's liquidPledging plugin allowing for 
    ///  extended functionality
    function getPledgeAdmin(uint64 idAdmin) constant returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled,
        address plugin)
    {
        PledgeAdmin storage m = findAdmin(idAdmin);
        adminType = m.adminType;
        addr = m.addr;
        name = m.name;
        url = m.url;
        commitTime = m.commitTime;
        parentProject = m.parentProject;
        canceled = m.canceled;
        plugin = address(m.plugin);
    }

////////
// Private methods
///////

    /// @notice This creates a Pledge with an initial amount of 0 if one is not
    ///  created already; otherwise it finds the pledge with the specified
    ///  attributes; all pledges technically exist, if the pledge hasn't been
    ///  created in this system yet it simply isn't in the hash array
    ///  hPledge2idx[] yet
    /// @param owner The owner of the pledge being looked up
    /// @param delegationChain The list of delegates in order of authority
    /// @param intendedProject The project this pledge will Fund after the
    ///  commitTime has passed
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param oldPledge This value is used to store the pledge the current
    ///  pledge was came from, and in the case a Project is canceled, the Pledge
    ///  will revert back to it's previous state
    /// @param paid The payment state: Pledged, Paying, or Paid 
    /// @return The hPledge2idx index number
    function findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PaymentState paid
        ) internal returns (uint64)
    {
        bytes32 hPledge = sha3(
            owner, delegationChain, intendedProject, commitTime, oldPledge, paid);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(
            0, owner, delegationChain, intendedProject, commitTime, oldPledge, paid));
        return idx;
    }

    /// @notice A getter to look up a Admin's details
    /// @param idAdmin The id for the Admin to lookup
    /// @return The PledgeAdmin struct for the specified Admin
    function findAdmin(uint64 idAdmin) internal returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

    /// @notice A getter to look up a Pledge's details
    /// @param idPledge The id for the Pledge to lookup
    /// @return The PledgeA struct for the specified Pledge
    function findPledge(uint64 idPledge) internal returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param n The Pledge that will be searched
    /// @param idxDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idxDelegae` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the maximum address.
    function getDelegateIdx(Pledge n, uint64 idxDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idxDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param n The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function getPledgeLevel(Pledge n) internal returns(uint) {
        if (n.oldPledge == 0) return 0;
        Pledge storage oldN = findPledge(n.oldPledge);
        return getPledgeLevel(oldN) + 1; // a loop lookup
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param n The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function maxCommitTime(Pledge n) internal returns(uint commitTime) {
        PledgeAdmin storage m = findAdmin(n.owner);
        commitTime = m.commitTime; // start with the owner's commitTime

        for (uint i=0; i<n.delegationChain.length; i++) {
            m = findAdmin(n.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

    /// @notice A getter to find the level of authority a specific Project has
    ///  using a self-referential loop
    /// @param m The Project being queried
    /// @return The level of authority a specific Project has
    function getProjectLevel(PledgeAdmin m) internal returns(uint) {
        assert(m.adminType == PledgeAdminType.Project);
        if (m.parentProject == 0) return(1);
        PledgeAdmin storage parentNM = findAdmin(m.parentProject);
        return getProjectLevel(parentNM);
    }

    /// @notice A getter to find if a specified Project has been canceled
    /// @param projectId The Admin id number used to specify the Project
    /// @return True if the Project has been canceled
    function isProjectCanceled(uint64 projectId) constant returns (bool) {
        PledgeAdmin storage m = findAdmin(projectId);
        if (m.adminType == PledgeAdminType.Giver) return false;
        assert(m.adminType == PledgeAdminType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled(m.parentProject);
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges 
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function getOldestPledgeNotCanceled(uint64 idPledge
        ) internal constant returns(uint64) {
        if (idPledge == 0) return 0;
        Pledge storage n = findPledge(idPledge);
        PledgeAdmin storage admin = findAdmin(n.owner);
        if (admin.adminType == PledgeAdminType.Giver) return idPledge;

        assert(admin.adminType == PledgeAdminType.Project);

        if (!isProjectCanceled(n.owner)) return idPledge;

        return getOldestPledgeNotCanceled(n.oldPledge);
    }

    /// @notice A check to see if the msg.sender is the owner or the
    ///  plugin contract for a specific Admin
    /// @param m The Admin being checked
    function checkAdminOwner(PledgeAdmin m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }
///////////////////////////
// Plugin Whitelist Methods
///////////////////////////

    function addValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = true;
    }

    function removeValidPlugin(bytes32 contractHash) external onlyOwner {
        pluginWhitelist[contractHash] = false;
    }

    function useWhitelist(bool useWhitelist) external onlyOwner {
        usePluginWhitelist = useWhitelist;
    }

    function isValidPlugin(address addr) public returns(bool) {
        if (!usePluginWhitelist || addr == 0x0) return true;

        bytes32 contractHash = getCodeHash(addr);

        return pluginWhitelist[contractHash];
    }

    function getCodeHash(address addr) public returns(bytes32) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}
