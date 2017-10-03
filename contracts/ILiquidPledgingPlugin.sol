pragma solidity ^0.4.11;

contract ILiquidPledgingPlugin {
    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the proposedCampaign transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the proposedCampaign receiving pledge to another party
    function beforeTransfer(
        uint64 noteManager,
        uint64 noteFrom,
        uint64 noteTo,
        uint64 context,
        uint amount
        ) returns (uint maxAllowed);
    function afterTransfer(
        uint64 noteManager,
        uint64 noteFrom,
        uint64 noteTo,
        uint64 context,
        uint amount);
}
