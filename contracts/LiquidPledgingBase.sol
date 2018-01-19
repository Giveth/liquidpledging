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

import "./ILiquidPledgingPlugin.sol";
import "giveth-common-contracts/contracts/Escapable.sol";
import "./PledgeAdmins.sol";
import "./EternalStorage.sol";

/// @dev This is an interface for `LPVault` which serves as a secure storage for
///  the ETH that backs the Pledges, only after `LiquidPledging` authorizes
///  payments can Pledges be converted for ETH
interface LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount) public;
    function () public payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquidPledging's most basic functions, mostly handling and searching the
///  data structures
contract LiquidPledgingBase is Escapable {
    using PledgeAdmins for EternalStorage;

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 10;
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    enum PledgeState { Pledged, Paying, Paid }

    struct Pledge {
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        PledgeState pledgeState; //  Pledged, Paying, Paid
    }

    EternalStorage public _storage;
    Pledge[] pledges;

    /// @dev this mapping allows you to search for a specific pledge's
    ///  index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;


    LPVault public vault;

    mapping (bytes32 => bool) pluginWhitelist;

    bool public usePluginWhitelist = true;

    // Duplicate Events from libs so they are added to the abi
    event GiverAdded(uint indexed idGiver);
    event GiverUpdated(uint indexed idGiver);
    event DelegateAdded(uint indexed idDelegate);
    event DelegateUpdated(uint indexed idDelegate);
    event ProjectAdded(uint indexed idProject);
    event ProjectUpdated(uint indexed idProject);

    // for testing
    event Gas(uint remainingGas);

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
    function LiquidPledgingBase(
        address _storageAddr,
        address _vault,
        address _escapeHatchCaller,
        address _escapeHatchDestination
    ) Escapable(_escapeHatchCaller, _escapeHatchDestination) public {
        _storage = EternalStorage(_storageAddr);
        vault = LPVault(_vault); // Assigns the specified vault
    }


/////////////////////////
// PledgeAdmin functions
/////////////////////////

    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint idGiver) {
        require(isValidPlugin(plugin)); // Plugin check

        return _storage.addGiver(
            name,
            url,
            commitTime,
            plugin
        );
    }

    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        _storage.updateGiver(
            idGiver,
            newAddr,
            newName,
            newUrl,
            newCommitTime
       );
    }

    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint64 idDelegate)
    {
        require(isValidPlugin(plugin)); // Plugin check

        return uint64(_storage.addDelegate(
            name,
            url,
            commitTime,
            plugin
        ));
    }

    function updateDelegate(
        uint64 idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        _storage.updateDelegate(
            idDelegate,
            newAddr,
            newName,
            newUrl,
            newCommitTime
        );
    }

    function addProject(
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint64 idProject)
    {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            // getProjectLevel will check that parentProject has a `Project` adminType
            require(_storage.getProjectLevel(parentProject) < MAX_SUBPROJECT_LEVEL);
        }

        return uint64(_storage.addProject(
                name,
                url,
                projectAdmin,
                parentProject,
                commitTime,
                plugin
            ));
    }

    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        _storage.updateProject(
            idProject,
            newAddr,
            newName,
            newUrl,
            newCommitTime
        );
    }


//////////
// Public constant functions
//////////

    /// @notice A constant getter that returns the total number of pledges
    /// @return The total number of Pledges in the system
    function numberOfPledges() public constant returns (uint) {
        return pledges.length - 1;
    }

    /// @notice A getter that returns the details of the specified pledge
    /// @param idPledge the id number of the pledge being queried
    /// @return the amount, owner, the number of delegates (but not the actual
    ///  delegates, the intendedProject (if any), the current commit time and
    ///  the previous pledge this pledge was derived from
    function getPledge(uint64 idPledge) public constant returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState pledgeState
    ) {
        Pledge storage p = findPledge(idPledge);
        amount = p.amount;
        owner = p.owner;
        nDelegates = uint64(p.delegationChain.length);
        intendedProject = p.intendedProject;
        commitTime = p.commitTime;
        oldPledge = p.oldPledge;
        pledgeState = p.pledgeState;
    }

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
    function getPledgeDelegate(uint64 idPledge, uint idxDelegate) public view returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage p = findPledge(idPledge);
        idDelegate = p.delegationChain[idxDelegate - 1];
        require(_storage.pledgeAdminsCount() >= idxDelegate);
        addr = _storage.getAdminAddr(idDelegate);
        name = _storage.getAdminName(idDelegate);
    }

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
//    function numberOfPledgeAdmins() public constant returns(uint) {
//        return _storage.pledgeAdminsCount();
//    }

    // can use _storage.getAdmin(idAdmin);
//    function getPledgeAdmin(uint64 idAdmin) public constant returns (
//        PledgeAdmins.PledgeAdminType adminType,
//        address addr,
//        string name,
//        string url,
//        uint64 commitTime,
//        uint64 parentProject,
//        bool canceled,
//        address plugin)
//    {
//        (adminType, addr, name, url, commitTime, parentProject, canceled, plugin) = _storage.getAdmin(idAdmin);
//    }

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
    /// @param state The pledge state: Pledged, Paying, or state
    /// @return The hPledge2idx index number
    function findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState state
        ) internal returns (uint64)
    {
        bytes32 hPledge = keccak256(
            owner, delegationChain, intendedProject, commitTime, oldPledge, state);
        uint64 idx = hPledge2idx[hPledge];
        if (idx > 0) return idx;
        idx = uint64(pledges.length);
        hPledge2idx[hPledge] = idx;
        pledges.push(Pledge(
            0, owner, delegationChain, intendedProject, commitTime, oldPledge, state));
        return idx;
    }

    /// @notice A getter to look up a Pledge's details
    /// @param idPledge The id for the Pledge to lookup
    /// @return The PledgeA struct for the specified Pledge
    function findPledge(uint64 idPledge) internal view returns (Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param p The Pledge that will be searched
    /// @param idDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idDelegate` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the NOTFOUND constant
    function getDelegateIdx(Pledge p, uint64 idDelegate) internal pure returns(uint64) {
        for (uint i=0; i < p.delegationChain.length; i++) {
            if (p.delegationChain[i] == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param p The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function getPledgeLevel(Pledge p) internal returns(uint) {
        if (p.oldPledge == 0) return 0;
        Pledge storage oldN = findPledge(p.oldPledge);
        return getPledgeLevel(oldN) + 1; // a loop lookup
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param p The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function maxCommitTime(Pledge p) internal view returns(uint commitTime) {
        uint adminsSize = _storage.pledgeAdminsCount();
        require(adminsSize >= p.owner);

        commitTime = _storage.getAdminCommitTime(p.owner); // start with the owner's commitTime

        for (uint i=0; i<p.delegationChain.length; i++) {
            require(adminsSize >= p.delegationChain[i]);
            uint delegateCommitTime = _storage.getAdminCommitTime(p.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (delegateCommitTime > commitTime) commitTime = delegateCommitTime;
        }
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges 
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function getOldestPledgeNotCanceled(
        uint64 idPledge
    ) internal constant returns(uint64)
    {
        if (idPledge == 0) return 0;
        Pledge storage p = findPledge(idPledge);

        PledgeAdmins.PledgeAdminType adminType = _storage.getAdminType(p.owner);
        if (adminType == PledgeAdmins.PledgeAdminType.Giver) return idPledge;
        assert(adminType == PledgeAdmins.PledgeAdminType.Project);

        if (!_storage.isProjectCanceled(p.owner)) return idPledge;

        return getOldestPledgeNotCanceled(p.oldPledge);
    }

    /// @notice A check to see if the msg.sender is the owner or the
    ///  plugin contract for a specific Admin
    /// @param idAdmin The id of the admin being checked
    function checkAdminOwner(uint idAdmin) internal constant {
        require((msg.sender == _storage.getAdminPlugin(idAdmin)) || (msg.sender == _storage.getAdminAddr(idAdmin)));
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

    function isValidPlugin(address addr) public view returns(bool) {
        if (!usePluginWhitelist || addr == 0x0) return true;

        bytes32 contractHash = getCodeHash(addr);

        return pluginWhitelist[contractHash];
    }

    function getCodeHash(address addr) public view returns(bytes32) {
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
