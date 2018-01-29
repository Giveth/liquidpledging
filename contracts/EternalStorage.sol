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

    bytes4 constant GET_UINT_SIG = bytes4(keccak256("getUIntValue(bytes32)"));
    bytes4 constant GET_ADDRESS_SIG = bytes4(keccak256("getAddressValue(bytes32)"));
    bytes4 constant GET_BYTES32_SIG = bytes4(keccak256("getBytes32Value(bytes32)"));
    bytes4 constant GET_BOOLEAN_SIG = bytes4(keccak256("getBooleanValue(bytes32)"));
    bytes4 constant GET_INT_SIG = bytes4(keccak256("getIntValue(bytes32)"));

    event Data(bytes d);
    event Val(uint val);
    event Sig(bytes4 sig);
    // Method for retrieving multiple storage values in a single call
    // This does not work for string or bytes storage
    /// @param data tightly packed call data of the form -- <sig><record>
    ///             where sig is the signature of the method to call & record
    ///             is the bytes32 record to fetch
    function multiCall(bytes data) public returns(bytes) {
        uint cnt = data.length / 36; // 32 byte uint value + 4 bytes for the sig
        require(data.length % 36 == 0); // 32 bytes data + 4 bytes sig for each
        bytes memory r = new bytes(cnt * 32); // allocate 32 bytes for each response
        // Data(data);

        for (var i = 0; i <= cnt; i++) {
            bytes4 sig;
            bytes32 d;
            assembly { 
                // First 32 bytes of data is the length of the bytes array, which we can ignore
                // 36 is the # of bytes each packed call takes. 4 bytes for the sig, 32 bytes for the record hash
                let offset := add(32, mul(i, 36))
                sig := mload(add(data, offset)) // load the sig for this packed call
                d := mload(add(data, add(offset, 4))) // load the record hash for this packed call
            }

            if ( sig == GET_UINT_SIG ) {
                uint vUInt = getUIntValue(d);
                assembly { 
                    mstore(add(r, mul(add(i, 1), 32)), vUInt) 
                }
            } else if ( sig == GET_ADDRESS_SIG ) {
                address vAddr = getAddressValue(d);
                assembly { 
                    mstore(add(r, mul(add(i, 1), 32)), vAddr)
                }
            } else if ( sig == GET_BYTES32_SIG ) {
                bytes32 val = getBytes32Value(d);
                assembly { 
                    mstore(add(r, mul(add(i, 1), 32)), val) 
                }
            } else if ( sig == GET_BOOLEAN_SIG ) { 
                bool vBool = getBooleanValue(d);
                assembly { 
                    mstore(add(r, mul(add(i, 1), 32)), vBool) 
                }
            } else if ( sig == GET_INT_SIG ) {
                int vInt = getIntValue(d);
                assembly { 
                    mstore(add(r, mul(add(i, 1), 32)), vInt) 
                }
            }
        }
        
        return r;
    }
}
