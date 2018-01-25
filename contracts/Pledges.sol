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

import "./EternallyPersistentLib.sol";
import "./LiquidPledgingStorage.sol";

contract Pledges is LiquidPledgingStorage {
    using EternallyPersistentLib for EternalStorage;

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 10;

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    // Constants used when dealing with storage/retrieval of Pledges
    string constant PLEDGE = "Pledge";
    bytes32 constant PLEDGES_ARRAY = keccak256("pledges");
    
    enum PledgeState { Pledged, Paying, Paid }

    struct Pledge {
        uint id; // the id of this Pledge
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        PledgeState pledgeState; //  Pledged, Paying, Paid
    }

///////////////
// Constructor
///////////////

    function Pledges(address _storage)
      LiquidPledgingStorage(_storage) public
    {
    }


/////////////////////////////
// Public constant functions
////////////////////////////

    /// @notice A constant getter that returns the total number of pledges
    /// @return The total number of Pledges in the system
    function numberOfPledges() public view returns (uint) {
        return _storage.stgCollectionLength(PLEDGES_ARRAY);
    }

    /// @notice A getter that returns the details of the specified pledge
    /// @param idPledge the id number of the pledge being queried
    /// @return the amount, owner, the number of delegates (but not the actual
    ///  delegates, the intendedProject (if any), the current commit time and
    ///  the previous pledge this pledge was derived from
    function getPledge(uint64 idPledge) public view returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState pledgeState
    ) {
        Pledge memory p = findPledge(idPledge);
        amount = p.amount;
        owner = p.owner;
        nDelegates = uint64(getPledgeDelegateCount(idPledge));
        intendedProject = p.intendedProject;
        commitTime = p.commitTime;
        oldPledge = p.oldPledge;
        pledgeState = p.pledgeState;
    }


////////////////////
// Internal methods
////////////////////

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
    ) internal returns (Pledge)
    {
        bytes32 hPledge = keccak256(owner, delegationChain, intendedProject, commitTime, oldPledge, state);
        uint id = _storage.getUIntValue(hPledge);
        if (id > 0) {
            return Pledge(
                id,
                getPledgeAmount(id), //TODO don't fetch this here b/c it may not be needed?
                owner,
                delegationChain,
                intendedProject,
                commitTime,
                oldPledge,
                state);
        }

        id = _storage.stgCollectionAddItem(PLEDGES_ARRAY);
        _storage.setUIntValue(hPledge, id);

        _storage.stgObjectSetUInt(PLEDGE, id, "owner", owner);
        if (intendedProject > 0) {
            _storage.stgObjectSetUInt(PLEDGE, id, "intendedProject", intendedProject);
        }
        if (commitTime > 0) {
            _storage.stgObjectSetUInt(PLEDGE, id, "commitTime", commitTime);
        }
        if (oldPledge > 0) {
            _storage.stgObjectSetUInt(PLEDGE, id, "oldPledge", oldPledge);
        }
        if (state != PledgeState.Pledged) {
            _storage.stgObjectSetUInt(PLEDGE, id, "state", uint(state));
        }

        if (delegationChain.length > 0) {
            _storage.setUIntValue(keccak256("delegationChain", id, "length"), delegationChain.length);

            // TODO pack these? possibly add array method to EternalStorage in anticipation of the new solidity abi encoder
            for (uint i = 0; i < delegationChain.length; i++) {
                _storage.setUIntValue(keccak256("delegationChain", id, i), delegationChain[i]);
            }
        }

        return Pledge(
            id,
            0,
            owner,
            delegationChain,
            intendedProject,
            commitTime,
            oldPledge,
            state);
    }

    /// @param idPledge the id of the pledge to load from storage
    /// @return The Pledge
    function findPledge(uint idPledge) internal view returns(Pledge) {
        require(idPledge <= numberOfPledges());

        uint amount = getPledgeAmount(idPledge);
        uint owner = getPledgeOwner(idPledge);
        uint intendedProject = getPledgeIntendedProject(idPledge);
        uint commitTime = getPledgeCommitTime(idPledge);
        uint oldPledge = getPledgeOldPledge(idPledge);
        PledgeState state = getPledgeState(idPledge);
        uint64[] memory delegates = getPledgeDelegates(idPledge);

        return Pledge(
            idPledge,
            amount,
            uint64(owner),
            delegates,
            uint64(intendedProject),
            uint64(commitTime),
            uint64(oldPledge),
            state
        );
    }

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param p The Pledge that will be searched
    /// @param idDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idDelegate` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the NOTFOUND constant
    function getDelegateIdx(Pledge p, uint64 idDelegate) internal pure returns(uint64) {
        for (uint i = 0; i < p.delegationChain.length; i++) {
            if (p.delegationChain[i] == idDelegate) {
                return uint64(i);
            }
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param idOldPledge The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function getPledgeLevel(uint idOldPledge) internal view returns(uint) {
        if (idOldPledge == 0) {
            return 0;
        }
        idOldPledge = _storage.stgObjectGetUInt(PLEDGE, idOldPledge, "oldPledge");
        return getPledgeLevel(idOldPledge) + 1; // a loop lookup
    }


//////////////////////////////////////////////////////
// Getters for individual attributes of a PledgeAdmin
//////////////////////////////////////////////////////

    function getPledgeOwner(uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(PLEDGE, idPledge, "owner");
    }

    function getPledgeDelegate(uint idPledge, uint index) internal view returns(uint) {
        return _storage.getUIntValue(keccak256("delegationChain", idPledge, index));
    }

    function getPledgeOldPledge(uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(PLEDGE, idPledge, "oldPledge");
    }

    function getPledgeAmount(uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(PLEDGE, idPledge, "amount");
    }

    function getPledgeIntendedProject(uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(PLEDGE, idPledge, "intendedProject");
    }

    function getPledgeCommitTime(uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(PLEDGE, idPledge, "commitTime");
    }

    function getPledgeState(uint idPledge) internal view returns(PledgeState) {
        return PledgeState(_storage.stgObjectGetUInt(PLEDGE, idPledge, "state"));
    }

    function getPledgeDelegates(uint idPledge) internal view returns(uint64[]) {
        //TODO pack/unpack chain
        uint length = getPledgeDelegateCount(idPledge);
        uint64[] memory delegates = new uint64[](length);
        for (uint i = 0; i < length; i++) {
            delegates[i] = uint64(getPledgeDelegate(idPledge, i));
        }
        return delegates;
    }

    function getPledgeDelegateCount(uint idPledge) internal view returns(uint) {
        return _storage.getUIntValue(keccak256("delegationChain", idPledge, "length"));
    }

    function setPledgeAmount(uint idPledge, uint amount) internal {
        _storage.stgObjectSetUInt(PLEDGE, idPledge, "amount", amount);
    }
}
