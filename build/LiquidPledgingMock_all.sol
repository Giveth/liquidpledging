
//File: contracts\ILiquidPledgingPlugin.sol
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


/// @dev `ILiquidPledgingPlugin` is the basic interface for any
///  liquid pledging plugin
contract ILiquidPledgingPlugin {

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated before a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    /// @param amount The amount of value that will be transfered.
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount ) returns (uint maxAllowed);

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated after a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    ///  @param amount The amount of value that will be transfered.
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    );
}

//File: contracts\LiquidPledgingBase.sol
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



/// @dev `Vault` serves as an interface to allow the `LiquidPledgingBase`
///  contract to interface with a `Vault` contract
contract LPVault {
    function authorizePayment(bytes32 _ref, address _dest, uint _amount);
    function () payable;
}

/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquid pledging. This function mostly handles the data structures
///  and basic CRUD methods for liquid pledging.
contract LiquidPledgingBase {

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
// Adminss functions
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
    ) returns (uint64 idxDelegate) { //TODO return index number

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

    event DelegateUpdated(uint64 indexed idxDelegate);

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
    function getPledgeDelegate(uint64 idPledge, uint _idxDelegate) constant returns(
        uint64 idxDelegate,
        address addr,
        string name
    ) {
        Pledge storage n = findPledge(idPledge);
        idxDelegate = n.delegationChain[_idxDelegate - 1];
        PledgeAdmin storage delegate = findAdmin(idxDelegate);
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
}

//File: contracts\LiquidPledging.sol
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

// Contract Imports


/// @dev `LiquidPleding` allows for liquid pledging through the use of
///  internal id structures and delegate chaining. All basic operations for
///  handling liquid pledging are supplied as well as plugin features
///  to allow for expanded functionality.
contract LiquidPledging is LiquidPledgingBase {


//////
// Constructor
//////

    /// @notice Basic constructor for LiquidPleding, also calls the
    ///  LiquidPledgingBase contract
    /// @dev This constructor  also calls the constructor 
    ///  for `LiquidPledgingBase`
    /// @param _vault The vault where ETH backing this pledge is stored
    function LiquidPledging(address _vault) LiquidPledgingBase(_vault) {
    }

    /// @notice This is how value enters into the system which creates pledges;
    ///  the token of value goes into the vault and the amount in the pledge
    ///  relevant to this Giver without delegates is increased, and a normal
    ///  transfer is done to the idReceiver
    /// @param idGiver Identifier of the giver thats donating.
    /// @param idReceiver To whom it's transfered. Can be the same giver,
    ///  another giver, a delegate or a project.
    function donate(uint64 idGiver, uint64 idReceiver) payable {
        if (idGiver == 0) {
            // default to 3 day commitTime
            idGiver = addGiver("", "", 259200, ILiquidPledgingPlugin(0x0));
        }

        PledgeAdmin storage sender = findAdmin(idGiver);

        checkAdminOwner(sender);

        require(sender.adminType == PledgeAdminType.Giver);

        uint amount = msg.value;

        require(amount > 0);

        vault.transfer(amount); // transfers the baseToken to the Vault
        uint64 idPledge = findOrCreatePledge(
            idGiver,
            new uint64[](0), //what is new?
            0,
            0,
            0,
            PaymentState.Pledged
        );


        Pledge storage nTo = findPledge(idPledge);
        nTo.amount += amount;

        Transfer(0, idPledge, amount);

        transfer(idGiver, idPledge, amount, idReceiver);
    }


    /// @notice Moves value between pledges
    /// @param idSender ID of the giver, delegate or project admin that is 
    ///  transferring the funds from Pledge to Pledge; this admin must have 
    ///  permissions to move the value
    /// @param idPledge Id of the pledge that's moving the value
    /// @param amount Quantity of value that's being moved
    /// @param idReceiver Destination of the value, can be a giver sending to 
    ///  a giver or a delegate, a delegate to another delegate or a project 
    ///  to pre-commit it to that project
    function transfer(
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    )
    {

        idPledge = normalizePledge(idPledge);

        Pledge storage n = findPledge(idPledge);
        PledgeAdmin storage receiver = findAdmin(idReceiver);
        PledgeAdmin storage sender = findAdmin(idSender);

        checkAdminOwner(sender);
        require(n.paymentState == PaymentState.Pledged);

        // If the sender is the owner
        if (n.owner == idSender) {
            if (receiver.adminType == PledgeAdminType.Giver) {
                transferOwnershipToGiver(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Project) {
                transferOwnershipToProject(idPledge, amount, idReceiver);
            } else if (receiver.adminType == PledgeAdminType.Delegate) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    n.delegationChain.length
                );
                appendDelegate(idPledge, amount, idReceiver);
            } else {
                assert(false);
            }
            return;
        }

        // If the sender is a delegate
        uint senderDIdx = getDelegateIdx(n, idSender);
        if (senderDIdx != NOTFOUND) {

            // If the receiver is another giver
            if (receiver.adminType == PledgeAdminType.Giver) {
                // Only accept to change to the original giver to
                // remove all delegates
                assert(n.owner == idReceiver);
                undelegate(idPledge, amount, n.delegationChain.length);
                return;
            }

            // If the receiver is another delegate
            if (receiver.adminType == PledgeAdminType.Delegate) {
                uint receiverDIdx = getDelegateIdx(n, idReceiver);

                // If the receiver is not in the delegate list
                if (receiverDIdx == NOTFOUND) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        n.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // after the sender, then all of the other delegates after the
                // sender are removed and the receiver is appended at the
                // end of the delegation chain
                } else if (receiverDIdx > senderDIdx) {
                    idPledge = undelegate(
                        idPledge,
                        amount,
                        n.delegationChain.length - senderDIdx - 1
                    );
                    appendDelegate(idPledge, amount, idReceiver);

                // If the receiver is already part of the delegate chain and is
                // before the sender, then the sender and all of the other
                // delegates after the RECEIVER are removed from the chain,
                // this is interesting because the delegate is removed from the
                // delegates that delegated to this delegate. Are there game theory
                // issues? should this be allowed?
                } else if (receiverDIdx <= senderDIdx) {
                    undelegate(
                        idPledge,
                        amount,
                        n.delegationChain.length - receiverDIdx - 1
                    );
                }
                return;
            }

            // If the delegate wants to support a project, they remove all
            // the delegates after them in the chain and choose a project
            if (receiver.adminType == PledgeAdminType.Project) {
                idPledge = undelegate(
                    idPledge,
                    amount,
                    n.delegationChain.length - senderDIdx - 1
                );
                proposeAssignProject(idPledge, amount, idReceiver);
                return;
            }
        }
        assert(false);  // It is not the owner nor any delegate.
    }


    /// @notice This method is used to withdraw value from the system.
    ///  This can be used by the givers to avoid committing the donation
    ///  or by project admin to use the Ether.
    /// @param idPledge Id of the pledge that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
    function withdraw(uint64 idPledge, uint amount) {

        idPledge = normalizePledge(idPledge);

        Pledge storage n = findPledge(idPledge);

        require(n.paymentState == PaymentState.Pledged);

        PledgeAdmin storage owner = findAdmin(n.owner);

        checkAdminOwner(owner);

        uint64 idNewPledge = findOrCreatePledge(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Paying
        );

        doTransfer(idPledge, idNewPledge, amount);

        vault.authorizePayment(bytes32(idNewPledge), owner.addr, amount);
    }

    /// @notice Method called by the vault to confirm a payment.
    /// @param idPledge Id of the pledge that wants to be withdrawn.
    /// @param amount Quantity of Ether that wants to be withdrawn.
    function confirmPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage n = findPledge(idPledge);

        require(n.paymentState == PaymentState.Paying);

        // Check the project is not canceled in the while.
        require(getOldestPledgeNotCanceled(idPledge) == idPledge);

        uint64 idNewPledge = findOrCreatePledge(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Paid
        );

        doTransfer(idPledge, idNewPledge, amount);
    }

    /// @notice Method called by the vault to cancel a payment.
    /// @param idPledge Id of the pledge that wants to be canceled for withdraw.
    /// @param amount Quantity of Ether that wants to be rolled back.
    function cancelPayment(uint64 idPledge, uint amount) onlyVault {
        Pledge storage n = findPledge(idPledge);

        require(n.paymentState == PaymentState.Paying); //TODO change to revert

        // When a payment is canceled, never is assigned to a project.
        uint64 oldPledge = findOrCreatePledge(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Pledged
        );

        oldPledge = normalizePledge(oldPledge);

        doTransfer(idPledge, oldPledge, amount);
    }

    /// @notice Method called to cancel this project.
    /// @param idProject Id of the projct that wants to be canceled.
    function cancelProject(uint64 idProject) {
        PledgeAdmin storage project = findAdmin(idProject);
        checkAdminOwner(project);
        project.canceled = true;

        CancelProject(idProject);
    }

    /// @notice Method called to cancel specific pledge.
    /// @param idPledge Id of the pledge that should be canceled.
    /// @param amount Quantity of Ether that wants to be rolled back.
    function cancelPledge(uint64 idPledge, uint amount) {
        idPledge = normalizePledge(idPledge);

        Pledge storage n = findPledge(idPledge);
        require(n.oldPledge != 0);

        PledgeAdmin storage m = findAdmin(n.owner);
        checkAdminOwner(m);

        uint64 oldPledge = getOldestPledgeNotCanceled(n.oldPledge);
        doTransfer(idPledge, oldPledge, amount);
    }


////////
// Multi pledge methods
////////

    // @dev This set of functions makes moving a lot of pledges around much more
    // efficient (saves gas) than calling these functions in series
    
    
    /// Bit mask used for dividing pledge amounts in Multi pledge methods
    uint constant D64 = 0x10000000000000000;

    /// @notice `mTransfer` allows for multiple pledges to be transferred
    ///  efficiently
    /// @param idSender ID of the giver, delegate or project admin that is
    ///  transferring the funds from Pledge to Pledge. This admin must have 
    ///  permissions to move the value
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    /// @param idReceiver Destination of the value, can be a giver sending
    ///  to a giver or a delegate or a delegate to another delegate or a
    ///  project to pre-commit it to that project
    function mTransfer(
        uint64 idSender,
        uint[] pledgesAmounts,
        uint64 idReceiver
    ) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            transfer(idSender, idPledge, amount, idReceiver);
        }
    }

    /// @notice `mWithdraw` allows for multiple pledges to be
    ///  withdrawn efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are
    ///  extrapolated using the D64 bitmask
    function mWithdraw(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            withdraw(idPledge, amount);
        }
    }

    /// @notice `mConfirmPayment` allows for multiple pledges to be confirmed
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mConfirmPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            confirmPayment(idPledge, amount);
        }
    }

    /// @notice `mCancelPayment` allows for multiple pledges to be canceled
    ///  efficiently
    /// @param pledgesAmounts An array of pledge amounts and IDs which are extrapolated
    ///  using the D64 bitmask
    function mCancelPayment(uint[] pledgesAmounts) {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64( pledgesAmounts[i] & (D64-1) );
            uint amount = pledgesAmounts[i] / D64;

            cancelPayment(idPledge, amount);
        }
    }

    /// @notice `mNormalizePledge` allows for multiple pledges to be
    ///  normalized efficiently
    /// @param pledges An array of pledge IDs which are extrapolated using
    ///  the D64 bitmask
    function mNormalizePledge(uint[] pledges) returns(uint64) {
        for (uint i = 0; i < pledges.length; i++ ) {
            uint64 idPledge = uint64( pledges[i] & (D64-1) );

            normalizePledge(idPledge);
        }
    }

////////
// Private methods
///////

    /// @notice `transferOwnershipToProject` allows for the transfer of
    ///  ownership to the project, but it can also be called to un-delegate
    ///  everyone by setting one's own id for the idReceiver
    /// @param idPledge Id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the project (or self to un-delegate)
    function transferOwnershipToProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage n = findPledge(idPledge);

        // Ensure that the pledge is not already at max pledge depth
        // and the project has not been canceled
        require(getPledgeLevel(n) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 oldPledge = findOrCreatePledge(
            n.owner,
            n.delegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Pledged
        );
        uint64 toPledge = findOrCreatePledge(
            idReceiver,                     // Set the new owner
            new uint64[](0),                // clear the delegation chain
            0,
            0,
            oldPledge,
            PaymentState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }   


    /// @notice `transferOwnershipToGiver` allows for the transfer of
    ///  value back to the Giver, value is placed in a pledged state
    ///  without being attached to a project, delegation chain, or time line.
    /// @param idPledge Id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the pledge
    function transferOwnershipToGiver(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        uint64 toPledge = findOrCreatePledge(
            idReceiver,
            new uint64[](0),
            0,
            0,
            0,
            PaymentState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge Id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's being chained.
    /// @param idReceiver The delegate to be added at the end of the chain
    function appendDelegate(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage n = findPledge(idPledge);

        require(n.delegationChain.length < MAX_DELEGATES);
        uint64[] memory newDelegationChain = new uint64[](
            n.delegationChain.length + 1
        );
        for (uint i = 0; i<n.delegationChain.length; i++) {
            newDelegationChain[i] = n.delegationChain[i];
        }

        // Make the last item in the array the idReceiver
        newDelegationChain[n.delegationChain.length] = idReceiver;

        uint64 toPledge = findOrCreatePledge(
            n.owner,
            newDelegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge Id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's shifted from delegates.
    /// @param q Number (or depth) to remove as delegates
    function undelegate(
        uint64 idPledge,
        uint amount,
        uint q
    ) internal returns (uint64){
        Pledge storage n = findPledge(idPledge);
        uint64[] memory newDelegationChain = new uint64[](
            n.delegationChain.length - q
        );
        for (uint i=0; i<n.delegationChain.length - q; i++) {
            newDelegationChain[i] = n.delegationChain[i];
        }
        uint64 toPledge = findOrCreatePledge(
            n.owner,
            newDelegationChain,
            0,
            0,
            n.oldPledge,
            PaymentState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);

        return toPledge;
    }

    /// @notice `proposeAssignProject` proposes the assignment of a pledge
    ///  to a specific project.
    /// @dev This function should potentially be named more specifically.
    /// @param idPledge Id of the pledge that will be assigned.
    /// @param amount Quantity of value this pledge leader would be assigned.
    /// @param idReceiver The project this pledge will potentially 
    ///  be assigned to.
    function proposeAssignProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal {
        Pledge storage n = findPledge(idPledge);

        require(getPledgeLevel(n) < MAX_SUBPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 toPledge = findOrCreatePledge(
            n.owner,
            n.delegationChain,
            idReceiver,
            uint64(getTime() + maxCommitTime(n)),
            n.oldPledge,
            PaymentState.Pledged
        );
        doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `doTransfer` is designed to allow for pledge amounts to be 
    ///  shifted around internally.
    /// @param from This is the Id from which value will be transfered.
    /// @param to This is the Id that value will be transfered to.
    /// @param _amount The amount of value that will be transfered.
    function doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = callPlugins(true, from, to, _amount);
        if (from == to) 
            return;
        if (amount == 0) 
            return;
        Pledge storage nFrom = findPledge(from);
        Pledge storage nTo = findPledge(to);
        require(nFrom.amount >= amount);
        nFrom.amount -= amount;
        nTo.amount += amount;

        Transfer(from, to, amount);
        callPlugins(false, from, to, amount);
    }

    /// @notice `normalizePledge` does 2 things:
    ///   #1: Checks to make sure that the pledges are correct. Then if 
    ///       a pledged project has already been committed, it changes
    ///       the owner to be the proposed project (The UI 
    ///       will have to read the commit time and manually do what
    ///       this function does to the pledge for the end user
    ///       at the expiration of the commitTime)
    ///
    ///   #2: Checks to make sure that if there has been a cancellation in the
    ///       chain of projects, the pledge's owner has been changed
    ///       appropriately.
    ///
    /// This function can be called by anybody at anytime on any pledge.
    /// In general it can be called to force the calls of the affected 
    /// plugins, which also need to be predicted by the UI
    /// @param idPledge This is the id of the pledge that will be normalized
    function normalizePledge(uint64 idPledge) returns(uint64) {

        Pledge storage n = findPledge(idPledge);

        // Check to make sure this pledge hasn't already been used 
        // or is in the process of being used
        if (n.paymentState != PaymentState.Pledged)
            return idPledge;

        // First send to a project if it's proposed and committed
        if ((n.intendedProject > 0) && ( getTime() > n.commitTime)) {
            uint64 oldPledge = findOrCreatePledge(
                n.owner,
                n.delegationChain,
                0,
                0,
                n.oldPledge,
                PaymentState.Pledged);
            uint64 toPledge = findOrCreatePledge(
                n.intendedProject,
                new uint64[](0),
                0,
                0,
                oldPledge,
                PaymentState.Pledged);
            doTransfer(idPledge, toPledge, n.amount);
            idPledge = toPledge;
            n = findPledge(idPledge);
        }

        toPledge = getOldestPledgeNotCanceled(idPledge);// TODO toPledge is pledge defined
        if (toPledge != idPledge) {
            doTransfer(idPledge, toPledge, n.amount);
        }

        return toPledge;
    }

/////////////
// Plugins
/////////////

    /// @notice `callPlugin` is used to trigger the general functions in the
    ///  plugin for any actions needed before and after a transfer happens.
    ///  Specifically what this does in relation to the plugin is something
    ///  that largely depends on the functions of that plugin. This function
    ///  is generally called in pairs, once before, and once after a transfer.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param adminId This should be the Id of the *trusted* individual
    ///  who has control over this plugin.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param context The situation that is triggering the plugin. See plugin
    ///  for a full description of contexts.
    /// @param amount The amount of value that is being transfered.
    function callPlugin(
        bool before,
        uint64 adminId,
        uint64 fromPledge,
        uint64 toPledge,
        uint64 context,
        uint amount
    ) internal returns (uint allowedAmount) {

        uint newAmount;
        allowedAmount = amount;
        PledgeAdmin storage admin = findAdmin(adminId);
        // Checks admin has a plugin assigned and a non-zero amount is requested
        if ((address(admin.plugin) != 0) && (allowedAmount > 0)) {
            // There are two seperate functions called in the plugin.
            // One is called before the transfer and one after
            if (before) {
                newAmount = admin.plugin.beforeTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                admin.plugin.afterTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    amount
                );
            }
        }
    }

    /// @notice `callPluginsPledge` is used to apply plugin calls to
    ///  the delegate chain and the intended project if there is one.
    ///  It does so in either a transferring or receiving context based
    ///  on the `idPledge` and  `fromPledge` parameters.
    /// @param before This toggle determines whether the plugin call is occuring
    ///  before or after a transfer.
    /// @param idPledge This is the Id of the pledge on which this plugin
    ///  is being called.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param amount The amount of value that is being transfered.
    function callPluginsPledge(
        bool before,
        uint64 idPledge,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
        // Determine if callPlugin is being applied in a receiving
        // or transferring context
        uint64 offset = idPledge == fromPledge ? 0 : 256;
        allowedAmount = amount;
        Pledge storage n = findPledge(idPledge);

        // Always call the plugin on the owner
        allowedAmount = callPlugin(
            before,
            n.owner,
            fromPledge,
            toPledge,
            offset,
            allowedAmount
        );

        // Apply call plugin to all delegates
        for (uint64 i=0; i<n.delegationChain.length; i++) {
            allowedAmount = callPlugin(
                before,
                n.delegationChain[i],
                fromPledge,
                toPledge,
                offset + i+1,
                allowedAmount
            );
        }

        // If there is an intended project also call the plugin in
        // either a transferring or receiving context based on offset
        // on the intended project
        if (n.intendedProject > 0) {
            allowedAmount = callPlugin(
                before,
                n.intendedProject,
                fromPledge,
                toPledge,
                offset + 255,
                allowedAmount
            );
        }
    }


    /// @notice `callPlugins` calls `callPluginsPledge` once for the transfer
    ///  context and once for the receiving context. The aggregated 
    ///  allowed amount is then returned.
    /// @param before This toggle determines whether the plugin call is occuring
    ///  before or after a transfer.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param amount The amount of value that is being transfered.    
    function callPlugins(
        bool before,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) {
        allowedAmount = amount;

        // Call the pledges plugins in the transfer context
        allowedAmount = callPluginsPledge(
            before,
            fromPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );

        // Call the pledges plugins in the receive context
        allowedAmount = callPluginsPledge(
            before,
            toPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );
    }

/////////////
// Test functions
/////////////

    /// @notice Basic helper function to return the current time
    function getTime() internal returns (uint) {
        return now;
    }

    // Event Delcerations
    event Transfer(uint64 indexed from, uint64 indexed to, uint amount);
    event CancelProject(uint64 indexed idProject);

}

//File: ./contracts/LiquidPledgingMock.sol
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



/// @dev `LiquidPledgingMock` allows for mocking up
///  a `LiquidPledging` contract with the added ability
///  to manipulate the block time for testing purposes.
contract LiquidPledgingMock is LiquidPledging {

    uint public mock_time;

    /// @dev `LiquidPledgingMock` creates a standard `LiquidPledging`
    ///  instance and sets the mocked time to the current blocktime.
    /// @param _vault The vault where ETH backing this pledge is stored    
    function LiquidPledgingMock(address _vault) LiquidPledging(_vault) {
        mock_time = now;
    }

    /// @dev `getTime` is a basic getter function for
    ///  the mock_time parameter
    function getTime() internal returns (uint) {
        return mock_time;
    }

    /// @dev `setMockedTime` is a basic setter function for
    ///  the mock_time parameter
    /// @param _t This is the value to which the mocked time
    ///  will be set.
    function setMockedTime(uint _t) {
        mock_time = _t;
    }
}
