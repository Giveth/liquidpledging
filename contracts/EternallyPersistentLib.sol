pragma solidity ^0.4.0;

import "./EternalStorage.sol";

library EternallyPersistentLib {

    // UInt
    //TODO if we use assembly here, we can save ~ 600 gas / call, due to skipping the extcodesize check that solidity adds.

    function stgObjectGetUInt(EternalStorage _storage, string class, uint id, string fieldName) internal view returns (uint) {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.getUIntValue(record);
    }

    function stgObjectSetUInt(EternalStorage _storage, string class, uint id, string fieldName, uint value) internal {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.setUIntValue(record, value);
    }

    // Boolean

    function stgObjectGetBoolean(EternalStorage _storage, string class, uint id, string fieldName) internal view returns (bool) {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.getBooleanValue(record);
    }

    function stgObjectSetBoolean(EternalStorage _storage, string class, uint id, string fieldName, bool value) internal {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.setBooleanValue(record, value);
    }

    // string

    function stgObjectGetString(EternalStorage _storage, string class, uint id, string fieldName) internal view returns (string) {
        bytes32 record = keccak256(class, id, fieldName);
        bytes4 sig = 0xa209a29c; // bytes4(keccak256("getStringValue(bytes32)"));
        string memory s;

        assembly {
            let ptr := mload(0x40)   //Find empty storage location using "free memory pointer"
            mstore(ptr, sig) //Place signature at beginning of empty storage
            mstore(add(ptr, 0x04), record) //Place first argument directly next to signature

            let result := staticcall(sub(gas, 10000), _storage, ptr, 0x24, 0, 0)

            let size := returndatasize
            returndatacopy(ptr, 0, size) // overwrite ptr to save a bit of gas

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { 
                mstore(0x40, add(ptr, size)) // update free mem location
                // We need to skip the first 32 bytes which contains the start offset of the returned byte array
                s := add(ptr, 0x20) // set the string
            }
        }

        return s;
    }

    function stgObjectSetString(EternalStorage _storage, string class, uint id, string fieldName, string value) internal {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.setStringValue(record, value);
    }

    // address

    function stgObjectGetAddress(EternalStorage _storage, string class, uint id, string fieldName) internal view returns (address) {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.getAddressValue(record);
    }

    function stgObjectSetAddress(EternalStorage _storage, string class, uint id, string fieldName, address value) internal {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.setAddressValue(record, value);
    }

    // bytes32

    function stgObjectGetBytes32(EternalStorage _storage, string class, uint id, string fieldName) internal view returns (bytes32) {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.getBytes32Value(record);
    }

    function stgObjectSetBytes32(EternalStorage _storage, string class, uint id, string fieldName, bytes32 value) internal {
        bytes32 record = keccak256(class, id, fieldName);
        return _storage.setBytes32Value(record, value);
    }

    // Array

    function stgCollectionAddItem(EternalStorage _storage, bytes32 idArray) internal returns (uint) {
        return _storage.incrementUIntValue(keccak256(idArray, "length"));
    }

    function stgCollectionLength(EternalStorage _storage, bytes32 idArray) internal view returns (uint) {
        return _storage.getUIntValue(keccak256(idArray, "length"));
    }

    function stgCollectionIdFromIdx(EternalStorage _storage, bytes32 idArray, uint idx) internal view returns (bytes32) {
        return _storage.getBytes32Value(keccak256(idArray, idx));
    }

    function stgUpgrade(EternalStorage _storage, address newContract) internal {
        _storage.changeOwnership(newContract);
    }
}