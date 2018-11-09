pragma solidity ^0.4.0;

// This is an extended version of aragon/os/acl/IACL.sol which includes all of the
// functions we need to not have to rely on aragon/os pinned solidity version
interface ILPVault {
    function ESCAPE_HATCH_CALLER_ROLE() external pure returns (bytes32);

    function initialize(address _vault) external; 

    function authorizePayment(bytes32 _ref, address _dest, address _token, uint _amount) external returns (uint);
}