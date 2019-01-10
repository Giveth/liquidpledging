pragma solidity ^0.4.24;

import "./lib/aragon/IDAOFactory.sol";
import "./lib/aragon/IACLEnhanced.sol";
import "./LPConstants.sol";
import "./ILiquidPledging.sol";
import "./ILPVault.sol";


contract LPFactory is LPConstants {
    IDAOFactory public daoFactory;
    address public vaultBase;
    address public lpBase;

    event DeployVault(address vault);
    event DeployLiquidPledging(address liquidPledging);

    constructor(IDAOFactory _daoFactory, address _vaultBase, address _lpBase) public {
        require(address(_daoFactory) != 0);
        require(_vaultBase != 0);
        require(_lpBase != 0);
        daoFactory = _daoFactory;
        vaultBase = _vaultBase;
        lpBase = _lpBase;
    }

    function newLP(address _root, address _escapeHatchDestination) external {
        IKernelEnhanced kernel = daoFactory.newDAO(this);
        IACLEnhanced acl = IACLEnhanced(kernel.acl());

        bytes32 appManagerRole = kernel.APP_MANAGER_ROLE();

        acl.createPermission(this, address(kernel), appManagerRole, this);

        ILPVault v = ILPVault(kernel.newAppInstance(VAULT_APP_ID, vaultBase));
        // deploy & register the lp instance w/ the kernel
        ILiquidPledging lp = ILiquidPledging(kernel.newAppInstance(LP_APP_ID, lpBase, "", true));
        v.initialize(address(lp));
        lp.initialize(address(v));

        // set the recoveryVault to the escapeHatchDestination
        kernel.setApp(kernel.APP_ADDR_NAMESPACE(), kernel.recoveryVaultAppId(), _escapeHatchDestination);

        bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();
        bytes32 hatchCallerRole = v.ESCAPE_HATCH_CALLER_ROLE();
        bytes32 pluginManagerRole = lp.PLUGIN_MANAGER_ROLE();

        acl.createPermission(_root, address(v), hatchCallerRole, _root);
        acl.createPermission(_root, address(lp), pluginManagerRole, _root);

        acl.grantPermission(_root, address(kernel), appManagerRole);
        acl.grantPermission(_root, address(acl), permRole);
        acl.revokePermission(this, address(kernel), appManagerRole);
        acl.revokePermission(this, address(acl), permRole);

        acl.setPermissionManager(_root, address(kernel), appManagerRole);
        acl.setPermissionManager(_root, address(acl), permRole);

        emit DeployVault(address(v));
        emit DeployLiquidPledging(address(lp));
    }
}