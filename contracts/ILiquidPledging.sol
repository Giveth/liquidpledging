pragma solidity ^0.4.0;

interface ILiquidPledging {
    function PLUGIN_MANAGER_ROLE() external pure returns (bytes32);

    function initialize(address _vault) external; 

    function confirmPayment(uint64 idPledge, uint amount) external;
    function cancelPayment(uint64 idPledge, uint amount) external;
}