pragma solidity ^0.4.0;

import "@aragon/os/contracts/lib/misc/ERCProxy.sol";
import "./IACLEnhanced.sol";

// This is an extended version of aragon/os/kernel/IKernel.sol which includes all of the
// functions we need to not have to rely on aragon/os pinned solidity version
// We add the *Enchanced suffix so we don't collide w/ @aragon/os/kernel/IKernel which is imported
// by AragonApp
interface IKernelEnhanced {
    // this is real a public constant, but this will work
    function APP_MANAGER_ROLE() external pure returns (bytes32);

    function initialize(IACLEnhanced _baseAcl, address _permissionsCreator) external;

    function newAppInstance(bytes32 _appId, address _appBase) external returns (ERCProxy appProxy);
    function newAppInstance(bytes32 _appId, address _appBase, bytes _initializePayload, bool _setDefault) external returns (ERCProxy appProxy);
    function newPinnedAppInstance(bytes32 _appId, address _appBase) external returns (ERCProxy appProxy);
    function newPinnedAppInstance(bytes32 _appId, address _appBase, bytes _initializePayload, bool _setDefault) external returns (ERCProxy appProxy);

    function setApp(bytes32 namespace, bytes32 appId, address app) external;

    function setRecoveryVaultAppId(bytes32 _recoveryVaultAppId) external;

    function CORE_NAMESPACE() external pure returns (bytes32);
    function APP_BASES_NAMESPACE() external pure returns (bytes32);
    function APP_ADDR_NAMESPACE() external pure returns (bytes32);
    function KERNEL_APP_ID() external pure returns (bytes32);
    function DEFAULT_ACL_APP_ID() external pure returns (bytes32);

    function getApp(bytes32 namespace, bytes32 appId) external view returns (address);
    function getRecoveryVault() external view returns (address);
    function acl() external view returns (IACLEnhanced);

    function hasPermission(address who, address where, bytes32 what, bytes how) external view returns (bool);

    //== contracts inherited by Kernel

    // this is really a public variable, but this will work
    function recoveryVaultAppId() external pure returns (bytes32);



}