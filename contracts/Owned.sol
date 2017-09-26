pragma solidity ^0.4.11;


/// @dev `Owned` is a base level contract that assigns an `owner` that can be
///  later changed
contract Owned {

    /// @dev `owner` is the only address that can call a function with this
    /// modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    /// @notice The Constructor assigns the account deploying the contract to be
    ///  the `owner`
    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    /// @notice `owner` can step down and assign some other address to this role
    ///  but after this function is called the current owner still has ownership
    ///  powers in this contract; change of ownership is a 2 step process
    /// @param _newOwner The address of the new owner. A simple contract with
    ///  the abilitiy to accept ownership but the inability to do anything else
    ///  can be used to create an unowned contract to achieve decentralization
    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    /// @notice `newOwner` can accept ownership over this contract 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}
