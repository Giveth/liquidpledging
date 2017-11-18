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

/// @dev `Vault` serves as an interface to allow the `LiquidPledgingBase`
///  contract to interface with a `Vault` contract
contract LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquid pledging. This function mostly handles the data structures
///  and basic CRUD methods for liquid pledging.
contract LiquidPledgingBase is Owned {
    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 20;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum PledgeAdminType { Giver, Delegate, Project }
    enum PaymentState { Pledged, Paying, Paid } // TODO name change Pledged

    /// @notice This struct defines the details of each the PledgeAdmin, these
    ///  PledgeAdmins can own pledges and act as delegates
    struct PledgeAdmin { // TODO name change PledgeAdmin
        PledgeAdminType adminType; // Giver, Delegate or Project
        address addr; // account or contract address for admin
        string name;
        string url;
        uint64 commitTime;  // In seconds, used for Givers' & Delegates' vetos
        uint64 parentProject;  // Only for projects
        bool canceled;      //Always false except for canceled projects
        // if the plugin is 0x0 then nothing happens if its a contract address
        // than that smart contract is called via the milestone contract
        ILiquidPledgingPlugin plugin; 
    }

    struct Pledge {
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // list of index numbers
        // TODO change the name only used for when delegates are 
        // pre-committing to a project
        uint64 intendedProject; 
        // When the intendedProject will become the owner
        uint64 commitTime;
        // this points to the Pledge[] index that the Pledge was derived from  
        uint64 oldPledge; 
        PaymentState paymentState;
    }

    Pledge[] pledges;
    PledgeAdmin[] admins; //The list of pledgeAdmins 0 means there is no admin
    LPVault public vault;

    // this mapping allows you to search for a specific pledge's 
    // index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;//TODO Fix typo
    mapping (bytes32 => bool) pluginWhitelist;

    bool public usePluginWhitelist = true;


/////
// Modifiers
/////

    /// @notice basic method to restrict a function to only the current vault
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }


//////
// Constructor
//////

    /// @notice The Constructor creates the `LiquidPledgingBase` 
    ///  on the blockchain
    /// @param _vault The vault where ETH backing this pledge is stored
    function LiquidPledgingBase(address _vault) {
        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
        vault = LPVault(_vault);
    }


///////
// Admin functions
//////

    /// @notice `addGiver` Creates a giver and adds them to the list of admins.
    /// @param name This is the name used to identify the giver.
    /// @param url This is a link to the givers profile or a representative site.
    /// @param commitTime Set the default commit time period for this giver.
    /// @param plugin This is givers liquid pledge plugin allowing for 
    ///  extended functionality.
    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idGiver) {
        require(isValidPlugin(plugin));
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

    /// @notice `updateGiver` allows for basic update operation to change the address,
    ///  name or commitTime associated with a specific giver.
    /// @param idGiver This is the internal ID used to specify the admin lookup
    ///  that coresponds to the giver.
    /// @param newAddr This parameter specifies an address to change the given
    ///  correspondancec between the giver's internal ID and an external address.
    /// @param newName This is the name used to identify the giver.
    /// @param newUrl This is a link to the givers profile or a representative site.
    /// @param newCommitTime Set the default commit time period for this giver.
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

    /// @notice `addDelegate` Creates a delegate and adds them to the list of admins.
    /// @param name This is the name used to identify the delegate.
    /// @param url This is a link to the delegates profile or a representative site.
    /// @param commitTime Set the default commit time period for this delegate.
    /// @param plugin This is givers liquid pledge plugin allowing for extended functionality.
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) returns (uint64 idDelegate) { //TODO return index number
        require(isValidPlugin(plugin));
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

    /// @notice `updateDelegate` allows for basic update operation to change the address,
    ///  name or commitTime associated with a specific delegate.
    /// @param idxDelegate This is the internal ID used to specify the admin lookup
    ///  that coresponds to the delegate.
    /// @param newAddr This parameter specifies an address to change the given
    ///  correspondancec between the giver's internal ID and an external address.
    /// @param newName This is the name used to identify the delegate.
    /// @param newUrl This is a link to the delegates profile or a representative site.
    /// @param newCommitTime Set the default commit time period for this giver.
    function updateDelegate(
        uint64 idxDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime) {
        PledgeAdmin storage delegate = findAdmin(idxDelegate);
        require(delegate.adminType == PledgeAdminType.Delegate);
        require(delegate.addr == msg.sender);
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;
        DelegateUpdated(idxDelegate);
    }

    event DelegateUpdated(uint64 indexed idDelegate);

    /// @notice `addProject` Creates a project and adds it to the list of admins.
    /// @param name This is the name used to identify the project.
    /// @param url This is a link to the projects profile or a representative site.
    /// @param projectAdmin This is the projects admin. This should be a trusted individual.
    /// @param parentProject If this project has a parent project or a project it's 
    ///  derived from use this parameter to supply it.
    /// @param commitTime Set the default commit time period for this project.
    /// @param plugin This is the projects liquid pledge plugin allowing for extended functionality.
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

    /// @notice `updateProject` allows for basic update operation to change the address,
    ///  name or commitTime associated with a specific project.
    /// @param idProject This is the internal ID used to specify the admin lookup
    ///  that coresponds to the project.
    /// @param newAddr This parameter specifies an address to change the given
    ///  correspondance between the project's internal ID and an external address.
    /// @param newName This is the name used to identify the project.
    /// @param newUrl This is a link to the projects profile or a representative site.
    /// @param newCommitTime Set the default commit time period for this project.
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

    /// @notice `numberOfPledges` is a constant getter that simply returns 
    ///  the number of pledges.
    function numberOfPledges() constant returns (uint) {
        return pledges.length - 1;
    }

    /// @notice `getPledge` is a constant getter that simply returns 
    ///  the amount, owner, the number of delegates, the intended project,
    ///  the current commit time and the previous pledge attached to a specific pledge.
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

    /// @notice `getPledgeDelegate` returns a single delegate given the pledge ID
    ///  and the delegate ID.
    /// @param idPledge The ID internally representing the pledge.
    /// @param idxDelegate The ID internally representing the delegate.
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

    /// @notice `numberOfPledgeAdmins` is a constant getter that simply returns 
    ///  the number of admins (Givers, Delegates and Projects are all "admins").
    function numberOfPledgeAdmins() constant returns(uint) {
        return admins.length - 1;
    }

    /// @notice `getPledgeAdmin` is a constant getter that simply returns 
    ///  the address, name, url, the current commit time and the previous
    ///  the parentProject, whether the project has been cancelled
    ///  and the projects plugin for a specific project.
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

    /// @notice All pledges technically exist. If the pledge hasn't been
    ///  created in this system yet it simply isn't in the hash array
    ///  hPledge2idx[] yet; this creates a Pledge with an initial amount of 0 if one is not
    ///  created already. Otherwise 
    /// @param owner The owner of the pledge being looked up.
    /// @param delegationChain The array of all delegates.
    /// @param intendedProject The intended project is the project this pledge will Fund.
    /// @param oldPledge This value is used to store the pledge the current pledge 
    ///  is "coming from."
    /// @param paid Based on the payment state this shows whether the pledge has been paid.
    function findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PaymentState paid
        ) internal returns (uint64)
    {
        bytes32 hPledge = sha3(owner, delegationChain, intendedProject, commitTime, oldPledge, paid);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(0, owner, delegationChain, intendedProject, commitTime, oldPledge, paid));
        return idx;
    }

    /// @notice `findAdmin` is a basic getter to return a 
    ///  specific admin (giver, delegate, or project)
    /// @param idAdmin The admin ID to lookup.
    function findAdmin(uint64 idAdmin) internal returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

    /// @notice `findPledge` is a basic getter to return a 
    ///  specific pledge 
    /// @param idPledge The admin ID to pledge.
    function findPledge(uint64 idPledge) internal returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    // a constant for the case that a delegate is requested that is not a delegate in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    /// @notice `getDelegateIdx` is a helper function that searches the delegationChain
    ///  for a specific delegate and level of delegation returns their idx in the 
    ///  delegation chain which reflect their level of authority. Returns MAX uint64
    ///  if no delegate is found.
    /// @param n The pledge that will be searched.
    /// @param idxDelegate The internal ID of the delegate that's searched for.
    function getDelegateIdx(Pledge n, uint64 idxDelegate) internal returns(uint64) {
        for (uint i=0; i<n.delegationChain.length; i++) {
            if (n.delegationChain[i] == idxDelegate) return uint64(i);
        }
        return NOTFOUND;
    }
 
    /// @notice `getPledgeLevel` is a helper function that returns the pledge "depth"
    ///  which can be used to check that transfers between Projects 
    ///  not violate MAX_INTERPROJECT_LEVEL
    /// @param n The pledge that will be searched.
    function getPledgeLevel(Pledge n) internal returns(uint) {
        if (n.oldPledge == 0) return 0; //changed
        Pledge storage oldN = findPledge(n.oldPledge);
        return getPledgeLevel(oldN) + 1;
    }

    /// @notice  `maxCommitTime` is a helper function that returns the maximum
    ///  commit time of the owner and all the delegates.
    /// @param n The pledge that will be searched.
    function maxCommitTime(Pledge n) internal returns(uint commitTime) {
        PledgeAdmin storage m = findAdmin(n.owner);
        commitTime = m.commitTime;

        for (uint i=0; i<n.delegationChain.length; i++) {
            m = findAdmin(n.delegationChain[i]);
            if (m.commitTime > commitTime) commitTime = m.commitTime;
        }
    }

    /// @notice `getProjectLevel` is a helper function that returns the project
    ///  level which can be used to check that there are not too many Projects
    ///  that violate MAX_SUBCAMPAIGNS_LEVEL.
    function getProjectLevel(PledgeAdmin m) internal returns(uint) {
        assert(m.adminType == PledgeAdminType.Project);
        if (m.parentProject == 0) return(1);
        PledgeAdmin storage parentNM = findAdmin(m.parentProject);
        return getProjectLevel(parentNM);
    }

    /// @notice `isProjectCanceled` is a basic helper function to check if
    ///  a project has been cancelled.
    /// @param projectId The internal id of the project to lookup.
    function isProjectCanceled(uint64 projectId) constant returns (bool) {
        PledgeAdmin storage m = findAdmin(projectId);
        if (m.adminType == PledgeAdminType.Giver) return false;
        assert(m.adminType == PledgeAdminType.Project);
        if (m.canceled) return true;
        if (m.parentProject == 0) return false;
        return isProjectCanceled(m.parentProject);
    }

    /// @notice `getOldestPledgeNotCanceled` is a helper function to get the oldest pledge
    ///  that hasn't been cancelled recursively.
    /// @param idPledge The starting place to lookup the pledges from
    function getOldestPledgeNotCanceled(uint64 idPledge) internal constant returns(uint64) { //todo rename
        if (idPledge == 0) return 0;
        Pledge storage n = findPledge(idPledge);
        PledgeAdmin storage admin = findAdmin(n.owner);
        if (admin.adminType == PledgeAdminType.Giver) return idPledge;

        assert(admin.adminType == PledgeAdminType.Project);

        if (!isProjectCanceled(n.owner)) return idPledge;

        return getOldestPledgeNotCanceled(n.oldPledge);
    }

    /// @notice `checkAdminOwner` is a helper function designed to throw
    ///  an error code if the user is not an admin. As PledgeAdmin is an
    ///  an internal structure this basically works like a modifier check
    ///  would however using internal data.
    /// @dev Looking into whether this can be done with a modifier would be good
    /// @param m A PledgeAdmin structure object.
    function checkAdminOwner(PledgeAdmin m) internal constant {
        require((msg.sender == m.addr) || (msg.sender == address(m.plugin)));
    }

////////
// Plugin Whitelist Methods
///////

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
