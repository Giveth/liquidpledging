pragma solidity ^0.4.0;


// This is an extended version of aragon/os/acl/IACL.sol which includes all of the
// functions we need to not have to rely on aragon/os pinned solidity version
// We add the *Enchanced suffix so we don't collide w/ @aragon/os/acl/IACL which is imported
// by AragonApp
interface IACLEnhanced {
    // these are really constants, but this will work
    function CREATE_PERMISSIONS_ROLE() external pure returns (bytes32);
    function EMPTY_PARAM_HASH() external pure returns (bytes32);
    function NO_PERMISSION() external pure returns (bytes32);
    function ANY_ENTITY() external pure returns (bytes32);
    function BURN_ENTITY() external pure returns (bytes32);

    function initialize(address _permissionsCreator) external;

    function createPermission(address _entity, address _app, bytes32 _role, address _manager) external;
    function grantPermission(address _entity, address _app, bytes32 _role) external;
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] _params) external;
    function revokePermission(address _entity, address _app, bytes32 _role) external;

    function setPermissionManager(address _newManager, address _app, bytes32 _role) external;
    function removePermissionManager(address _app, bytes32 _role) external;

    function createBurnedPermission(address _app, bytes32 _role) external;
    function burnPermissionManager(address _app, bytes32 _role) external;

    function getPermissionParamsLength(address _entity, address _app, bytes32 _role) external view returns (uint);
    function getPermissionParam(address _entity, address _app, bytes32 _role, uint _index) external view returns (uint8, uint8, uint240);
    function getPermissionManager(address _app, bytes32 _role) external view returns (address);

    function hasPermission(address _who, address _where, bytes32 _what, bytes _how) external view returns (bool);
    function hasPermission(address _who, address _where, bytes32 _what, uint256[] _how) external view returns (bool);
    function hasPermission(address _who, address _where, bytes32 _what) external view returns (bool);

    function evalParams(bytes32 _paramsHash, address _who, address _where, bytes32 _what, uint256[] _how) external view returns (bool);
}