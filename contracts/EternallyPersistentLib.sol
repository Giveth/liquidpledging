pragma solidity ^0.4.0;

import "./EternalStorage.sol";

library EternallyPersistentLib {

    // UInt

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
        bytes4 sig = bytes4(keccak256("getStringValue(bytes32)"));
        //Function signature
        address a = address(_storage);
        string memory s;

        assembly {
            let x := mload(0x40)   //Find empty storage location using "free memory pointer"
            mstore(x, sig) //Place signature at begining of empty storage
            mstore(add(x, 0x04), record) //Place first argument directly next to signature

            let success := call(//This is the critical change (Pop the top stack value)
            5000, //5k gas
            a, //To addr
            0, //No value
            x, //Inputs are stored at location x
            0x24, //Inputs are 36 byes long
            x, //Store output over input (saves space)
            0x80) //Outputs are 32 bytes long

            let strL := mload(add(x, 0x20))   // Load the length of the sring

            jumpi(ask_more, gt(strL, 64))

            mstore(0x40, add(x, add(strL, 0x40)))

            s := add(x, 0x20)
        //                return(x, add(strL, 0x40))
            ask_more :
            mstore(x, sig) //Place signature at begining of empty storage
            mstore(add(x, 0x04), record) //Place first argument directly next to signature

            success := call(//This is the critical change (Pop the top stack value)
            5000, //5k gas
            a, //To addr
            0, //No value
            x, //Inputs are stored at location x
            0x24, //Inputs are 36 byes long
            x, //Store output over input (saves space)
            add(0x40, strL)) //Outputs are 32 bytes long

            mstore(0x40, add(x, add(strL, 0x40)))
            s := add(x, 0x20)

        //                return(x, add(strL, 0x40))
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

//    function stgCollectionAddItem(bytes32 idArray, bytes32 idItem) internal returns (uint64) {
    function stgCollectionAddItem(EternalStorage _storage, bytes32 idArray) internal returns (uint) {

        uint length = _storage.getUIntValue(keccak256(idArray, "length"));


        // Set the position in the array as a field so it can be deleted
//        _storage.setUIntValue(keccak256(idArray, idItem, "_idx"), length);

        // Add the object to the array
//        _storage.setBytes32Value(keccak256(idArray, length), idItem);


        // Increment the size of the array
        length++;
        _storage.setUIntValue(keccak256(idArray, "length"), length);

        return length;
    }

//    function stgCollectionRemoveItem(EternalStorage _storage, bytes32 idArray, bytes32 idItem) internal {
//        uint idx = _storage.getUIntValue(keccak256(idArray, idItem, "_idx"));
//
//        uint length = _storage.getUIntValue(keccak256(idArray, "length"));
//        length --;
//
//        // Move the last element ot the array to this place
//        bytes32 lastId = _storage.getBytes32Value(keccak256(idArray, length));
//        _storage.setBytes32Value(keccak256(idArray, idx), lastId);
//        _storage.setUIntValue(keccak256(idArray, lastId, "_idx"), idx);
//
//
//        // Decrement the length
//        _storage.setUIntValue(keccak256(idArray, "length"), length);
//
//        // Cleanup the last element of the array
//        _storage.setBytes32Value(keccak256(idArray, length), 0);
//
//        _storage.setUIntValue(keccak256(idArray, idItem, "_idx"), 0);
//    }

    function stgCollectionLength(EternalStorage _storage, bytes32 idArray) internal view returns (uint) {
        return _storage.getUIntValue(keccak256(idArray, "length"));
    }

    function stgCollectionIdFromIdx(EternalStorage _storage, bytes32 idArray, uint idx) internal view returns (bytes32) {
        return _storage.getBytes32Value(keccak256(idArray, idx));
    }


//    bytes32 lastId;

//    function stgGetNewId() internal returns (bytes32) {
//        lastId = keccak256(lastId, now);
//        return lastId;
//    }

    function stgUpgrade(EternalStorage _storage, address newContract) internal {
        _storage.changeOwnership(newContract);
    }

}