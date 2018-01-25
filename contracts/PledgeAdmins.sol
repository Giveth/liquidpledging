pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
                  Arthur Lunn

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
import "./EternallyPersistentLib.sol";
import "./LiquidPledgingStorage.sol";
import "./LiquidPledgingPlugins.sol";

contract PledgeAdmins is LiquidPledgingStorage, LiquidPledgingPlugins {
    using EternallyPersistentLib for EternalStorage;

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    // Constants used when dealing with storage/retrieval of PledgeAdmins
    string constant PLEDGE_ADMIN = "PledgeAdmin";
    bytes32 constant PLEDGE_ADMINS_ARRAY = keccak256("pledgeAdmins");

    //TODO we can pack some of these struct values, which should save space. TEST THIS
    //TODO making functions public may lower deployment cost, but increase gas / tx costs. TEST THIS
    //TODO is it cheaper to issue a storage check before updating? where should this be done? EternalStorage?

    enum PledgeAdminType { Giver, Delegate, Project }

    // Events
    event GiverAdded(uint indexed idGiver);
    event GiverUpdated(uint indexed idGiver);
    event DelegateAdded(uint indexed idDelegate);
    event DelegateUpdated(uint indexed idDelegate);
    event ProjectAdded(uint indexed idProject);
    event ProjectUpdated(uint indexed idProject);


///////////////
// Constructor
///////////////

    function PledgeAdmins(address _storage)
      LiquidPledgingStorage(_storage)
      LiquidPledgingPlugins() public
    {
    }

////////////////////
// Public functions
////////////////////

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
        uint commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint idGiver)
    {
        require(isValidPlugin(plugin)); // Plugin check

        idGiver = _storage.stgCollectionAddItem(PLEDGE_ADMINS_ARRAY);

        // Save the fields
        // don't set adminType to save gas, b/c 0 is Giver
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idGiver, "addr", msg.sender);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idGiver, "name", name);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idGiver, "url", url);
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idGiver, "commitTime", commitTime);
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idGiver, "plugin", address(plugin));

        GiverAdded(idGiver);
    }

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
        uint idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(idGiver) == PledgeAdminType.Giver); // Must be a Giver
        require(getAdminAddr(idGiver) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idGiver, "addr", newAddr);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idGiver, "name", newName);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idGiver, "url", newUrl);
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idGiver, "commitTime", newCommitTime);

        GiverUpdated(idGiver);
    }

    /// @notice Creates a Delegate Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Delegate
    /// @param url The link to the Delegate's profile often an IPFS hash
    /// @param commitTime Sets the length of time in seconds that this delegate
    ///  can be vetoed. Whenever this delegate is in a delegate chain the time
    ///  allowed to veto any event must be greater than or equal to this time.
    /// @param plugin This is Delegate's liquid pledge plugin allowing for
    ///  extended functionality
    /// @return idxDelegate The id number used to reference this Delegate within
    ///  the PLEDGE_ADMIN array
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint idDelegate) 
    {
        require(isValidPlugin(plugin)); // Plugin check

        idDelegate = _storage.stgCollectionAddItem(PLEDGE_ADMINS_ARRAY);

        // Save the fields
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idDelegate, "adminType", uint(PledgeAdminType.Delegate));
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idDelegate, "addr", msg.sender);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idDelegate, "name", name);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idDelegate, "url", url);
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idDelegate, "commitTime", commitTime);
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idDelegate, "plugin", address(plugin));

        DelegateAdded(idDelegate);
    }

    /// @notice Updates a Delegate's info to change the address, name, url, or
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Delegate
    /// @param idDelegate The Admin id number used to specify the Delegate
    /// @param newAddr The new address that represents this Delegate
    /// @param newName The new name used to identify the Delegate
    /// @param newUrl The new link to the Delegate's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds that this
    ///  delegate can be vetoed. Whenever this delegate is in a delegate chain
    ///  the time allowed to veto any event must be greater than or equal to
    ///  this time.
    function updateDelegate(
        uint idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(idDelegate) == PledgeAdminType.Delegate);
        require(getAdminAddr(idDelegate) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idDelegate, "addr", newAddr);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idDelegate, "name", newName);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idDelegate, "url", newUrl);
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idDelegate, "commitTime", newCommitTime);

        DelegateUpdated(idDelegate);
    }

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
    ) public returns (uint idProject) 
    {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            // getProjectLevel will check that parentProject has a `Project` adminType
            require(getProjectLevel(parentProject) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = _storage.stgCollectionAddItem(PLEDGE_ADMINS_ARRAY);//, idProject);

        // Save the fields
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idProject, "adminType", uint(PledgeAdminType.Project));
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idProject, "addr", projectAdmin);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idProject, "name", name);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idProject, "url", url);

        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idProject, "parentProject", parentProject);

        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idProject, "commitTime", commitTime);
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idProject, "plugin", address(plugin));

        ProjectAdded(idProject);
    }

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
        uint idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(idProject) == PledgeAdminType.Project);
        require(getAdminAddr(idProject) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(PLEDGE_ADMIN, idProject, "addr", newAddr);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idProject, "name", newName);
        _storage.stgObjectSetString(PLEDGE_ADMIN, idProject, "url", newUrl);
        _storage.stgObjectSetUInt(PLEDGE_ADMIN, idProject, "commitTime", newCommitTime);

        ProjectUpdated(idProject);
    }


/////////////////////////////
// Public constant functions
/////////////////////////////

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
    function numberOfPledgeAdmins() public constant returns(uint) {
        return _storage.stgCollectionLength(PLEDGE_ADMINS_ARRAY);
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
    function getPledgeAdmin(uint idAdmin) public view returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled,
        address plugin
    ) {
        adminType = getAdminType(idAdmin);
        addr = getAdminAddr(idAdmin);
        name = getAdminName(idAdmin);
        url = _storage.stgObjectGetString(PLEDGE_ADMIN, idAdmin, "url");
        commitTime = uint64(getAdminCommitTime(idAdmin));

        // parentProject & canceled only belong to Project admins,
        // so don't waste the gas to fetch the data
        if (adminType == PledgeAdminType.Project) {
            parentProject = uint64(getAdminParentProject(idAdmin));
            canceled = getAdminCanceled(idAdmin);
        }

        plugin = getAdminPlugin(idAdmin);
    }


///////////////////
// Internal methods
///////////////////

    /// @notice A getter to find if a specified Project has been canceled
    /// @param projectId The Admin id number used to specify the Project
    /// @return True if the Project has been canceled
    function isProjectCanceled(uint projectId)
        internal constant returns (bool)
    {
        require(numberOfPledgeAdmins() >= projectId);

        PledgeAdminType adminType = getAdminType(projectId);

        if (adminType == PledgeAdminType.Giver) {
            return false;
        }
        assert(adminType == PledgeAdminType.Project);

        if (getAdminCanceled(projectId)) {
            return true;
        }

        uint parentProject = getAdminParentProject(projectId);
        if (parentProject == 0) {
            return false;
        }

        return isProjectCanceled(parentProject);
    }

    /// @notice Find the level of authority a specific Project has
    ///  using a recursive loop
    /// @param idProject The id of the Project being queried
    /// @return The level of authority a specific Project has
    function getProjectLevel(uint idProject) internal returns(uint) {
        assert(getAdminType(idProject) == PledgeAdminType.Project);
        uint parentProject = getAdminParentProject(idProject);
        if (parentProject == 0) {
            return(1);
        }
        return getProjectLevel(parentProject) + 1;
    }


//////////////////////////////////////////////////////
// Getters for individual attributes of a PledgeAdmin
//////////////////////////////////////////////////////

    function getAdminType(
        uint idAdmin
    ) internal view returns (PledgeAdminType)
    {
        return PledgeAdminType(_storage.stgObjectGetUInt(PLEDGE_ADMIN, idAdmin, "adminType"));
    }

    function getAdminAddr(
        uint idAdmin
    ) internal view returns (address)
    {
        return _storage.stgObjectGetAddress(PLEDGE_ADMIN, idAdmin, "addr");
    }

    function getAdminName(
        uint idAdmin
    ) internal view returns (string)
    {
        return _storage.stgObjectGetString(PLEDGE_ADMIN, idAdmin, "name");
    }

    function getAdminParentProject(
        uint idAdmin
    ) internal view returns (uint)
    {
        return _storage.stgObjectGetUInt(PLEDGE_ADMIN, idAdmin, "parentProject");
    }

    function getAdminCanceled(
        uint idAdmin
    ) internal view returns (bool)
    {
        return _storage.stgObjectGetBoolean(PLEDGE_ADMIN, idAdmin, "canceled");
    }

    function getAdminPlugin(
        uint idAdmin
    ) internal view returns (address)
    {
        return _storage.stgObjectGetAddress(PLEDGE_ADMIN, idAdmin, "plugin");
    }

    function getAdminCommitTime(
        uint idAdmin
    ) internal view returns (uint)
    {
        return _storage.stgObjectGetUInt(PLEDGE_ADMIN, idAdmin, "commitTime");
    }
}
