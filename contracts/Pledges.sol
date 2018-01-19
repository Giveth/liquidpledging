pragma solidity ^0.4.18;

import "./EternallyPersistentLib.sol";

library Pledges {
    using EternallyPersistentLib for EternalStorage;

    string constant class = "Pledge";
    bytes32 constant pledges = keccak256("pledges");
    
    enum PledgeState { Pledged, Paying, Paid }

    struct Pledge {
        uint id;
        uint amount;
        uint64 owner; // PledgeAdmin
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        PledgeState pledgeState; //  Pledged, Paying, Paid
    }

    function pledgesCount(EternalStorage _storage) internal view returns(uint) {
        return _storage.stgCollectionLength(pledges);
    }

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
        EternalStorage _storage,
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        PledgeState state
    ) internal returns (uint64)
    {
        bytes32 hPledge = keccak256(owner, delegationChain, intendedProject, commitTime, oldPledge, state);
        uint id = _storage.getUIntValue(hPledge);
        if (id > 0) return uint64(id);

        id = _storage.stgCollectionAddItem(pledges);
        _storage.setUIntValue(hPledge, id);

        _storage.stgObjectSetUInt(class, id, "owner", owner);
        if (intendedProject > 0) {
            _storage.stgObjectSetUInt(class, id, "intendedProject", intendedProject);
        }
        if (commitTime > 0) {
            _storage.stgObjectSetUInt(class, id, "commitTime", commitTime);
        }
        if (oldPledge > 0) {
            _storage.stgObjectSetUInt(class, id, "oldPledge", oldPledge);
        }
        _storage.stgObjectSetUInt(class, id, "state", uint(state));

        if (delegationChain.length > 0) {
            _storage.setUIntValue(keccak256("delegationChain", id, "length"), delegationChain.length);

            // TODO pack these? possibly add array method to EternalStorage in anticipation of the new solidity abi encoder
            for (uint i=0; i < delegationChain.length; i++) {
                _storage.setUIntValue(keccak256("delegationChain", id, i), delegationChain[i]);
            }
        }

        return uint64(id);
    }

    function findPledge(EternalStorage _storage, uint idPledge) internal view returns(Pledge) {
        require(idPledge <= pledgesCount(_storage));

        uint amount = getPledgeAmount(_storage, idPledge);
        uint owner = getPledgeOwner(_storage, idPledge);
        uint intendedProject = getPledgeIntendedProject(_storage, idPledge);
        uint commitTime = getPledgeCommitTime(_storage, idPledge);
        uint oldPledge = getPledgeOldPledge(_storage, idPledge);
        PledgeState state = getPledgeState(_storage, idPledge);
        uint64[] memory delegates = getPledgeDelegates(_storage, idPledge);

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

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param idPledge The Pledge that will be searched
    /// @param idDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idDelegate` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the NOTFOUND constant
    function getDelegateIdx(EternalStorage _storage, uint idPledge, uint64 idDelegate) internal view returns(uint64) {
        //TODO pack/unpack chain
        uint length = getPledgeDelegateCount(_storage, idPledge);
        for (uint i=0; i < length; i++) {
            if (getPledgeDelegate(_storage, idPledge, i) == idDelegate) return uint64(i);
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param idOldPledge The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function getPledgeLevel(EternalStorage _storage, uint idOldPledge) internal view returns(uint) {
        if (idOldPledge == 0) return 0;
        idOldPledge = _storage.stgObjectGetUInt(class, idOldPledge, "oldPledge");
        return getPledgeLevel(_storage, idOldPledge) + 1; // a loop lookup
    }

    function getPledgeOwner(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(class, idPledge, "owner");
    }

    function getPledgeDelegate(EternalStorage _storage, uint idPledge, uint index) internal view returns(uint) {
        return _storage.getUIntValue(keccak256("delegationChain", idPledge, index));
    }

    function getPledgeOldPledge(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(class, idPledge, "oldPledge");
    }

    function getPledgeAmount(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(class, idPledge, "amount");
    }

    function getPledgeIntendedProject(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(class, idPledge, "intendedProject");
    }

    function getPledgeCommitTime(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.stgObjectGetUInt(class, idPledge, "commitTime");
    }

    function getPledgeState(EternalStorage _storage, uint idPledge) internal view returns(PledgeState) {
        return PledgeState(_storage.stgObjectGetUInt(class, idPledge, "state"));
    }

    function getPledgeDelegates(EternalStorage _storage, uint idPledge) internal view returns(uint64[]) {
        //TODO pack/unpack chain
        uint length = getPledgeDelegateCount(_storage, idPledge);
        uint64[] memory delegates = new uint64[](length);
        for (uint i=0; i < length; i++) {
            delegates[i] = uint64(getPledgeDelegate(_storage, idPledge, i));
        }
        return delegates;
    }

    function getPledgeDelegateCount(EternalStorage _storage, uint idPledge) internal view returns(uint) {
        return _storage.getUIntValue(keccak256("delegationChain", idPledge, "length"));
    }

    function setPledgeAmount(EternalStorage _storage, uint idPledge, uint amount) internal {
        _storage.stgObjectSetUInt(class, idPledge, "amount", amount);
    }

}
