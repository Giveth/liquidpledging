pragma solidity ^0.4.18;

import "./EternalStorage.sol";

contract LiquidPledgingStorage {

    EternalStorage public _storage;

    function LiquidPledgingStorage(address _s) public {
        _storage = EternalStorage(_s);
    }
}