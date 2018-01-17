pragma solidity ^0.4.17;

import "./ILiquidPledgingPlugin.sol";
import "./EternallyPersistentLib.sol";

library PledgeAdmins {
    using EternallyPersistentLib for EternalStorage;

    //TODO we can pack some of these struct values, which should save space. TEST THIS
    //TODO making functions public may lower deployment cost, but increase gas / tx costs. TEST THIS
    //TODO is it cheaper to issue a storage check before updating? where should this be done? EternalStorage?

    string constant class = "PledgeAdmins";
    bytes32 constant admins = keccak256("pledgeAdmins");

    enum PledgeAdminType { Giver, Delegate, Project }

    /// @dev This struct defines the details of a `PledgeAdmin` which are
    ///  commonly referenced by their index in the `admins` array
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

//    PledgeAdmins[] admins;

//    function PledgeAdmins(address _storage) EternallyPersistent(_storage) public {
//    function setStorage(address _storage) internal {
//        require(address(adminStorage == 0x0));
//        adminStorage = EternallyPersistent(_storage);
//         TODO maybe make an init method?
//        admins.length = 1; // we reserve the 0 admin
//    }

    /// @notice Creates a Giver Admin with the `msg.sender` as the Admin address
    /// @param name The name used to identify the Giver
    /// @param url The link to the Giver's profile often an IPFS hash
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param plugin This is Giver's liquid pledge plugin allowing for
    ///  extended functionality
    /// @return idGiver The id number used to reference this Admin
    function addGiver(
        EternalStorage _storage,
        string name,
        string url,
        uint commitTime,
        ILiquidPledgingPlugin plugin
    ) internal returns (uint idGiver) {
//        bytes32 idGuardian = bytes32(addrGuardian);
//
//        if (guardian_exists(addrGuardian)) {
//            _storage.stgObjectSetString( "Guardian", idGuardian, "name", name);
//            return;
//        }

        idGiver = _storage.stgCollectionAddItem(admins);//, idGiver);

        // Save the fields
        _storage.stgObjectSetUInt(class, idGiver, "adminType", uint(PledgeAdminType.Giver));
        _storage.stgObjectSetAddress(class, idGiver, "addr", msg.sender);
        _storage.stgObjectSetString(class, idGiver, "name", name);
        _storage.stgObjectSetString(class, idGiver, "url", url);
        _storage.stgObjectSetUInt(class, idGiver, "commitTime", commitTime);
        _storage.stgObjectSetAddress(class, idGiver, "plugin", address(plugin));

        GiverAdded(idGiver);
    }

    event GiverAdded(uint indexed idGiver);

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
        EternalStorage _storage,
        uint idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(_storage, idGiver) == PledgeAdminType.Giver); // Must be a Giver
        require(getAdminAddr(_storage, idGiver) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(class, idGiver, "addr", newAddr);
        _storage.stgObjectSetString(class, idGiver, "name", newName);
        _storage.stgObjectSetString(class, idGiver, "url", newUrl);
        _storage.stgObjectSetUInt(class, idGiver, "commitTime", newCommitTime);

        GiverUpdated(idGiver);
    }

    event GiverUpdated(uint indexed idGiver);

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
        EternalStorage _storage,
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) internal returns (uint idDelegate) {
        idDelegate = _storage.stgCollectionAddItem(admins);//, idDelegate);

        // Save the fields
        _storage.stgObjectSetUInt(class, idDelegate, "adminType", uint(PledgeAdminType.Delegate));
        _storage.stgObjectSetAddress(class, idDelegate, "addr", msg.sender);
        _storage.stgObjectSetString(class, idDelegate, "name", name);
        _storage.stgObjectSetString(class, idDelegate, "url", url);
        _storage.stgObjectSetUInt(class, idDelegate, "commitTime", commitTime);
        _storage.stgObjectSetAddress(class, idDelegate, "plugin", address(plugin));

        DelegateAdded(idDelegate);
    }

    event DelegateAdded(uint indexed idDelegate);

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
        EternalStorage _storage,
        uint idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(_storage, idDelegate) == PledgeAdminType.Delegate);
        require(getAdminAddr(_storage, idDelegate) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(class, idDelegate, "addr", newAddr);
        _storage.stgObjectSetString(class, idDelegate, "name", newName);
        _storage.stgObjectSetString(class, idDelegate, "url", newUrl);
        _storage.stgObjectSetUInt(class, idDelegate, "commitTime", newCommitTime);

        DelegateUpdated(idDelegate);
    }

    event DelegateUpdated(uint indexed idDelegate);

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
        EternalStorage _storage,
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) internal returns (uint idProject) {
        idProject = _storage.stgCollectionAddItem(admins);//, idProject);

        // Save the fields
        _storage.stgObjectSetUInt(class, idProject, "adminType", uint(PledgeAdminType.Project));
        _storage.stgObjectSetAddress(class, idProject, "addr", projectAdmin);
        _storage.stgObjectSetString(class, idProject, "name", name);
        _storage.stgObjectSetString(class, idProject, "url", url);

        // NOTICE: we do not verify that the parentProject has a `Project` adminType
        // this is expected to be done by the calling method
        _storage.stgObjectSetUInt(class, idProject, "parentProject", parentProject);

        _storage.stgObjectSetUInt(class, idProject, "commitTime", commitTime);
        _storage.stgObjectSetAddress(class, idProject, "plugin", address(plugin));

        ProjectAdded(idProject);
    }

    event ProjectAdded(uint indexed idProject);

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
        EternalStorage _storage,
        uint idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) public
    {
        require(getAdminType(_storage, idProject) == PledgeAdminType.Project);
        require(getAdminAddr(_storage, idProject) == msg.sender); // Current addr had to send this tx

        // Save the fields
        _storage.stgObjectSetAddress(class, idProject, "addr", newAddr);
        _storage.stgObjectSetString(class, idProject, "name", newName);
        _storage.stgObjectSetString(class, idProject, "url", newUrl);
        _storage.stgObjectSetUInt(class, idProject, "commitTime", newCommitTime);

        ProjectUpdated(idProject);
    }

    event ProjectUpdated(uint indexed idAdmin);

    function cancelProject(EternalStorage _storage, uint idProject) internal {
        _storage.stgObjectSetBoolean(class, idProject, "canceled", true);
        CancelProject(idProject);
    }

    /// @notice A getter to find if a specified Project has been canceled
    /// @param projectId The Admin id number used to specify the Project
    /// @return True if the Project has been canceled
    function isProjectCanceled(EternalStorage _storage, uint projectId)
        public constant returns (bool)
    {
        require(pledgeAdminsCount(_storage) >= projectId);

        PledgeAdminType adminType = getAdminType(_storage, projectId);

        if (adminType == PledgeAdminType.Giver) return false;
        assert(adminType == PledgeAdminType.Project);

        if (getAdminCanceled(_storage, projectId)) return true;

        uint parentProject = getAdminParentProject(_storage, projectId);
        if (parentProject == 0) return false;

        return isProjectCanceled(_storage, parentProject);
    }

    event CancelProject(uint indexed idProject);

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
    //TODO I think using 'size' in both Pledges lib & PledgeAdmins lib will cause a conflict since they use the same storage contract
//    function size(EternalStorage _storage) constant returns(uint) {
    function pledgeAdminsCount(EternalStorage _storage) public constant returns(uint) {
        return _storage.stgCollectionLength(admins);// - 1;
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
    function getAdmin(EternalStorage _storage, uint idAdmin) internal view returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint parentProject,
        bool canceled,
        address plugin
    )
    {
        adminType = getAdminType(_storage, idAdmin);
        addr = getAdminAddr(_storage, idAdmin);
        name = getAdminName(_storage, idAdmin);
        url = _storage.stgObjectGetString(class, idAdmin, "url");
        commitTime = uint64(getAdminCommitTime(_storage, idAdmin));

        // parentProject & canceled only belong to Project admins,
        // so don't waste the gas to fetch the data
        if (adminType == PledgeAdminType.Project) {
            parentProject = getAdminParentProject(_storage, idAdmin);
            canceled = getAdminCanceled(_storage, idAdmin);
        }

        plugin = getAdminPlugin(_storage, idAdmin);
    }

    /// @notice Find the level of authority a specific Project has
    ///  using a recursive loop
    /// @param idProject The id of the Project being queried
    /// @return The level of authority a specific Project has
    function getProjectLevel(EternalStorage _storage, uint idProject) public returns(uint) {
        assert(getAdminType(_storage, idProject) == PledgeAdminType.Project);
        uint parentProject = getAdminParentProject(_storage, idProject);
        if (parentProject == 0) return(1);
        return getProjectLevel(_storage, parentProject) + 1;
    }

//18,446,744,070,000,000,000 uint64
//1,516,144,546,228,000 uint56

////////
// Methods to fetch individual attributes of a PledgeAdmin
///////

    // costs ~10k gas
    function getAdminType(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (PledgeAdminType)
    {
        return PledgeAdminType(_storage.stgObjectGetUInt(class, idAdmin, "adminType"));
    }

    // costs ~10k gas
    function getAdminAddr(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (address)
    {
        return _storage.stgObjectGetAddress(class, idAdmin, "addr");
    }

    // costs ~8k gas
    function getAdminName(
        EternalStorage _storage,
        uint idAdmin
    ) internal view returns (string)
    {
        return _storage.stgObjectGetString(class, idAdmin, "name");
    }

    // costs ~10k gas
    function getAdminParentProject(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (uint)
    {
        return _storage.stgObjectGetUInt(class, idAdmin, "parentProject");
    }

    // costs ~10k gas
    function getAdminCanceled(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (bool)
    {
        return _storage.stgObjectGetBoolean(class, idAdmin, "canceled");
    }

    // costs ~10k gas
    function getAdminPlugin(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (address)
    {
        return _storage.stgObjectGetAddress(class, idAdmin, "plugin");
    }

    // costs ~10k gas
    function getAdminCommitTime(
        EternalStorage _storage,
        uint idAdmin
    ) public view returns (uint)
    {
        return _storage.stgObjectGetUInt(class, idAdmin, "commitTime");
    }

}
