
//File: ./contracts/ILiquidPledgingPlugin.sol
pragma solidity ^0.4.11;

contract ILiquidPledgingPlugin {

    /// @param context In which context it is affected.
    ///  0 -> owner from
    ///  1 -> First delegate from
    ///  2 -> Second delegate from
    ///  ...
    ///  255 -> proposedProject from
    ///
    ///  256 -> owner to
    ///  257 -> First delegate to
    ///  258 -> Second delegate to
    ///  ...
    ///  511 -> proposedProject to
    function onTransfer(uint64 noteManager, uint64 noteFrom, uint64 noteTo, uint64 context, uint amount) returns (uint maxAllowed);
}
