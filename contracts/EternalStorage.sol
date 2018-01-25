pragma solidity ^0.4.0;

import "node_modules/giveth-common-contracts/contracts/Escapable.sol";

contract EternalStorage is Escapable {

    mapping(bytes32 => uint) UIntStorage;
    mapping(bytes32 => int) IntStorage;
    mapping(bytes32 => bool) BooleanStorage;
    mapping(bytes32 => address) AddressStorage;
    mapping(bytes32 => string) StringStorage;
    mapping(bytes32 => bytes) BytesStorage;
    mapping(bytes32 => bytes32) Bytes32Storage;

    function EternalStorage(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination) public {
    }

    /// UInt Storage

    function getUIntValue(bytes32 record) public view returns (uint) {
        return UIntStorage[record];
    }

    function setUIntValue(bytes32 record, uint value) public onlyOwner {
        UIntStorage[record] = value;
    }

    /// Int Storage

    function getIntValue(bytes32 record) public view returns (int) {
        return IntStorage[record];
    }

    function setIntValue(bytes32 record, int value) public onlyOwner {
        IntStorage[record] = value;
    }

    /// Address Storage

    function getAddressValue(bytes32 record) public view returns (address) {
        return AddressStorage[record];
    }

    function setAddressValue(bytes32 record, address value) public onlyOwner {
        AddressStorage[record] = value;
    }

    /// String Storage

    function getStringValue(bytes32 record) public view returns (string) {
        return StringStorage[record];
    }

    function setStringValue(bytes32 record, string value) public onlyOwner {
        StringStorage[record] = value;
    }

    /// Bytes Storage

    function getBytesValue(bytes32 record) public view returns (bytes) {
        return BytesStorage[record];
    }

    function setBytesValue(bytes32 record, bytes value) public onlyOwner {
        BytesStorage[record] = value;
    }

    /// Bytes Storage

    function getBytes32Value(bytes32 record) public view returns (bytes32) {
        return Bytes32Storage[record];
    }

    function setBytes32Value(bytes32 record, bytes32 value) public onlyOwner {
        Bytes32Storage[record] = value;
    }

    /// Boolean Storage

    function getBooleanValue(bytes32 record) public view returns (bool) {
        return BooleanStorage[record];
    }

    function setBooleanValue(bytes32 record, bool value) public onlyOwner {
        BooleanStorage[record] = value;
    }
}
