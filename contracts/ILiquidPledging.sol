pragma solidity ^0.4.0;

// This is an extended version of aragon/os/acl/IACL.sol which includes all of the
// functions we need to not have to rely on aragon/os pinned solidity version
interface ILiquidPledging {
    function PLUGIN_MANAGER_ROLE() external pure returns (bytes32);

    function initialize(address _vault) external; 

    function confirmPayment(uint64 idPledge, uint amount) external;
    function cancelPayment(uint64 idPledge, uint amount) external;
}