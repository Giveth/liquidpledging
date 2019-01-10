

///File: @aragon/os/contracts/acl/IACL.sol

pragma solidity ^0.4.18;


interface IACL {
    function initialize(address permissionsCreator) public;
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}


///File: @aragon/os/contracts/common/IVaultRecoverable.sol

pragma solidity ^0.4.18;


interface IVaultRecoverable {
    function transferToVault(address token) external;

    function allowRecoverability(address token) public view returns (bool);
    function getRecoveryVault() public view returns (address);
}


///File: @aragon/os/contracts/kernel/IKernel.sol

pragma solidity ^0.4.18;





// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IVaultRecoverable {
    event SetApp(bytes32 indexed namespace, bytes32 indexed name, bytes32 indexed id, address app);

    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 name, address app) public returns (bytes32 id);
    function getApp(bytes32 id) public view returns (address);
}


///File: @aragon/os/contracts/kernel/KernelStorage.sol

pragma solidity 0.4.18;


contract KernelConstants {
    /*
    bytes32 constant public CORE_NAMESPACE = keccak256("core");
    bytes32 constant public APP_BASES_NAMESPACE = keccak256("base");
    bytes32 constant public APP_ADDR_NAMESPACE = keccak256("app");

    bytes32 constant public KERNEL_APP_ID = apmNamehash("kernel");
    bytes32 constant public KERNEL_APP = keccak256(CORE_NAMESPACE, KERNEL_APP_ID);

    bytes32 constant public ACL_APP_ID = apmNamehash("acl");
    bytes32 constant public ACL_APP = keccak256(APP_ADDR_NAMESPACE, ACL_APP_ID);
    */
    bytes32 constant public CORE_NAMESPACE = 0xc681a85306374a5ab27f0bbc385296a54bcd314a1948b6cf61c4ea1bc44bb9f8;
    bytes32 constant public APP_BASES_NAMESPACE = 0xf1f3eb40f5bc1ad1344716ced8b8a0431d840b5783aea1fd01786bc26f35ac0f;
    bytes32 constant public APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
    bytes32 constant public ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;
    bytes32 constant public APM_NODE = 0x9065c3e7f7b7ef1ef4e53d2d0b8e0cef02874ab020c1ece79d5f0d3d0111c0ba;
    bytes32 constant public KERNEL_APP_ID = 0x3b4bf6bf3ad5000ecf0f989d5befde585c6860fea3e574a4fab4c49d1c177d9c;
    bytes32 constant public KERNEL_APP = 0x2b7d19d0575c228f8d9326801e14149d284dc5bb7b1541c5ad712ae4b2fcaadb;
    bytes32 constant public ACL_APP_ID = 0xe3262375f45a6e2026b7e7b18c2b807434f2508fe1a2a3dfb493c7df8f4aad6a;
    bytes32 constant public ACL_APP = 0x4b8e03a458a6ccec5d9077c2490964c1333dd3c72e2db408d7d9a7a36ef5c41a;

}


contract KernelStorage is KernelConstants {
    mapping (bytes32 => address) public apps;
    bytes32 public recoveryVaultId;
}


///File: @aragon/os/contracts/acl/ACLSyntaxSugar.sol

pragma solidity ^0.4.18;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[] r) {}

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}


///File: @aragon/os/contracts/lib/misc/ERCProxy.sol

pragma solidity ^0.4.18;


contract ERCProxy {
    uint256 constant public FORWARDING = 1;
    uint256 constant public UPGRADEABLE = 2;

    function proxyType() public pure returns (uint256 proxyTypeId);
    function implementation() public view returns (address codeAddr);
}


///File: @aragon/os/contracts/apps/AppStorage.sol

pragma solidity ^0.4.18;




contract AppStorage {
    IKernel public kernel;
    bytes32 public appId;
    address internal pinnedCode; // used by Proxy Pinned
    uint256 internal initializationBlock; // used by Initializable
    uint256[95] private storageOffset; // forces App storage to start at after 100 slots
    uint256 private offset;
}


///File: @aragon/os/contracts/common/Initializable.sol

pragma solidity ^0.4.18;




contract Initializable is AppStorage {
    modifier onlyInit {
        require(initializationBlock == 0);
        _;
    }

    modifier isInitialized {
        require(initializationBlock > 0);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        initializationBlock = getBlockNumber();
    }

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }
}


///File: @aragon/os/contracts/common/IsContract.sol

pragma solidity ^0.4.18;


contract IsContract {
    function isContract(address _target) internal view returns (bool) {
        if (_target == address(0)) {
            return false;
        }

        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}


///File: @aragon/os/contracts/common/EtherTokenConstant.sol

pragma solidity ^0.4.18;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address constant public ETH = address(0);
}


///File: @aragon/os/contracts/lib/zeppelin/token/ERC20Basic.sol

pragma solidity ^0.4.11;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


///File: @aragon/os/contracts/lib/zeppelin/token/ERC20.sol

pragma solidity ^0.4.11;


import './ERC20Basic.sol';


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


///File: @aragon/os/contracts/common/VaultRecoverable.sol

pragma solidity ^0.4.18;







contract VaultRecoverable is IVaultRecoverable, EtherTokenConstant, IsContract {
    /**
     * @notice Send funds to recovery Vault. This contract should never receive funds,
     *         but in case it does, this function allows one to recover them.
     * @param _token Token balance to be sent to recovery vault.
     */
    function transferToVault(address _token) external {
        require(allowRecoverability(_token));
        address vault = getRecoveryVault();
        require(isContract(vault));

        if (_token == ETH) {
            vault.transfer(this.balance);
        } else {
            uint256 amount = ERC20(_token).balanceOf(this);
            ERC20(_token).transfer(vault, amount);
        }
    }

    /**
    * @dev By default deriving from AragonApp makes it recoverable
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return true;
    }
}


///File: @aragon/os/contracts/common/DelegateProxy.sol

pragma solidity 0.4.18;





contract DelegateProxy is ERCProxy, IsContract {
    uint256 constant public FWD_GAS_LIMIT = 10000;

    /**
    * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
    * @param _dst Destination address to perform the delegatecall
    * @param _calldata Calldata for the delegatecall
    */
    function delegatedFwd(address _dst, bytes _calldata) internal {
        delegatedFwd(_dst, _calldata, 0);
    }

    /**
    * @dev Performs a delegatecall and returns whatever the delegatecall returned (entire context execution will return!)
    * @param _dst Destination address to perform the delegatecall
    * @param _calldata Calldata for the delegatecall
    * @param _minReturnSize Minimum size the call needs to return, if less than that it will revert
    */
    function delegatedFwd(address _dst, bytes _calldata, uint256 _minReturnSize) internal {
        require(isContract(_dst));
        uint256 size;
        uint256 result;
        uint256 fwd_gas_limit = FWD_GAS_LIMIT;

        assembly {
            result := delegatecall(sub(gas, fwd_gas_limit), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            size := returndatasize
        }

        require(size >= _minReturnSize);

        assembly {
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}


///File: @aragon/os/contracts/common/DepositableDelegateProxy.sol

pragma solidity 0.4.18;




contract DepositableDelegateProxy is DelegateProxy {
    event ProxyDeposit(address sender, uint256 value);

    function () payable public {
        // send / transfer
        if (msg.gas < FWD_GAS_LIMIT) {
            require(msg.value > 0 && msg.data.length == 0);
            ProxyDeposit(msg.sender, msg.value);
        } else { // all calls except for send or transfer
            address target = implementation();
            delegatedFwd(target, msg.data);
        }
    }
}


///File: @aragon/os/contracts/apps/AppProxyBase.sol

pragma solidity 0.4.18;






contract AppProxyBase is AppStorage, DepositableDelegateProxy, KernelConstants {
    /**
    * @dev Initialize AppProxy
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyBase(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public {
        kernel = _kernel;
        appId = _appId;

        // Implicit check that kernel is actually a Kernel
        // The EVM doesn't actually provide a way for us to make sure, but we can force a revert to
        // occur if the kernel is set to 0x0 or a non-code address when we try to call a method on
        // it.
        address appCode = getAppBase(appId);

        // If initialize payload is provided, it will be executed
        if (_initializePayload.length > 0) {
            require(isContract(appCode));
            // Cannot make delegatecall as a delegateproxy.delegatedFwd as it
            // returns ending execution context and halts contract deployment
            require(appCode.delegatecall(_initializePayload));
        }
    }

    function getAppBase(bytes32 _appId) internal view returns (address) {
        return kernel.getApp(keccak256(APP_BASES_NAMESPACE, _appId));
    }
}


///File: @aragon/os/contracts/apps/AppProxyUpgradeable.sol

pragma solidity 0.4.18;




contract AppProxyUpgradeable is AppProxyBase {
    /**
    * @dev Initialize AppProxyUpgradeable (makes it an upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyUpgradeable(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {

    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return getAppBase(appId);
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }
}


///File: @aragon/os/contracts/apps/AppProxyPinned.sol

pragma solidity 0.4.18;




contract AppProxyPinned is AppProxyBase {
    /**
    * @dev Initialize AppProxyPinned (makes it an un-upgradeable Aragon app)
    * @param _kernel Reference to organization kernel for the app
    * @param _appId Identifier for app
    * @param _initializePayload Payload for call to be made after setup to initialize
    */
    function AppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {
        pinnedCode = getAppBase(appId);
        require(pinnedCode != address(0));
    }

    /**
     * @dev ERC897, the address the proxy would delegate calls to
     */
    function implementation() public view returns (address) {
        return pinnedCode;
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return FORWARDING;
    }
}


///File: @aragon/os/contracts/factory/AppProxyFactory.sol

pragma solidity 0.4.18;





contract AppProxyFactory {
    event NewAppProxy(address proxy, bool isUpgradeable, bytes32 appId);

    function newAppProxy(IKernel _kernel, bytes32 _appId) public returns (AppProxyUpgradeable) {
        return newAppProxy(_kernel, _appId, new bytes(0));
    }

    function newAppProxy(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyUpgradeable) {
        AppProxyUpgradeable proxy = new AppProxyUpgradeable(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy), true, _appId);
        return proxy;
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId) public returns (AppProxyPinned) {
        return newAppProxyPinned(_kernel, _appId, new bytes(0));
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyPinned) {
        AppProxyPinned proxy = new AppProxyPinned(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy), false, _appId);
        return proxy;
    }
}


///File: @aragon/os/contracts/kernel/Kernel.sol

pragma solidity 0.4.18;











contract Kernel is IKernel, KernelStorage, Initializable, IsContract, AppProxyFactory, ACLSyntaxSugar, VaultRecoverable {
    // Hardocde constant to save gas
    //bytes32 constant public APP_MANAGER_ROLE = keccak256("APP_MANAGER_ROLE");
    //bytes32 constant public DEFAULT_VAULT_ID = keccak256(APP_ADDR_NAMESPACE, apmNamehash("vault"));
    bytes32 constant public APP_MANAGER_ROLE = 0xb6d92708f3d4817afc106147d969e229ced5c46e65e0a5002a0d391287762bd0;
    bytes32 constant public DEFAULT_VAULT_ID = 0x4214e5fd6d0170d69ea641b5614f5093ebecc9928af51e95685c87617489800e;

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initializes a kernel instance along with its ACL and sets `_permissionsCreator` as the entity that can create other permissions
    * @param _baseAcl Address of base ACL app
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(address _baseAcl, address _permissionsCreator) onlyInit public {
        initialized();

        IACL acl = IACL(newAppProxy(this, ACL_APP_ID));

        _setApp(APP_BASES_NAMESPACE, ACL_APP_ID, _baseAcl);
        _setApp(APP_ADDR_NAMESPACE, ACL_APP_ID, acl);

        acl.initialize(_permissionsCreator);

        recoveryVaultId = DEFAULT_VAULT_ID;
    }

    /**
    * @dev Create a new instance of an app linked to this kernel
    * @param _name Name of the app
    * @param _appBase Address of the app's base implementation
    * @return AppProxy instance
    */
    function newAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (ERCProxy appProxy) {
        return newAppInstance(_name, _appBase, false);
    }

    /**
    * @dev Create a new instance of an app linked to this kernel and set its base
    *      implementation if it was not already set
    * @param _name Name of the app
    * @param _appBase Address of the app's base implementation
    * @param _setDefault Whether the app proxy app is the default one.
    *        Useful when the Kernel needs to know of an instance of a particular app,
    *        like Vault for escape hatch mechanism.
    * @return AppProxy instance
    */
    function newAppInstance(bytes32 _name, address _appBase, bool _setDefault) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (ERCProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxy(this, _name);
        // By calling setApp directly and not the internal functions, we make sure the params are checked
        // and it will only succeed if sender has permissions to set something to the namespace.
        if (_setDefault) {
            setApp(APP_ADDR_NAMESPACE, _name, appProxy);
        }
    }

    /**
    * @dev Create a new pinned instance of an app linked to this kernel
    * @param _name Name of the app
    * @param _appBase Address of the app's base implementation
    * @return AppProxy instance
    */
    function newPinnedAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (ERCProxy appProxy) {
        return newPinnedAppInstance(_name, _appBase, false);
    }

    /**
    * @dev Create a new pinned instance of an app linked to this kernel and set
    *      its base implementation if it was not already set
    * @param _name Name of the app
    * @param _appBase Address of the app's base implementation
    * @param _setDefault Whether the app proxy app is the default one.
    *        Useful when the Kernel needs to know of an instance of a particular app,
    *        like Vault for escape hatch mechanism.
    * @return AppProxy instance
    */
    function newPinnedAppInstance(bytes32 _name, address _appBase, bool _setDefault) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (ERCProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxyPinned(this, _name);
        // By calling setApp directly and not the internal functions, we make sure the params are checked
        // and it will only succeed if sender has permissions to set something to the namespace.
        if (_setDefault) {
            setApp(APP_ADDR_NAMESPACE, _name, appProxy);
        }
    }

    /**
    * @dev Set the resolving address of an app instance or base implementation
    * @param _namespace App namespace to use
    * @param _name Name of the app
    * @param _app Address of the app
    * @return ID of app
    */
    function setApp(bytes32 _namespace, bytes32 _name, address _app) auth(APP_MANAGER_ROLE, arr(_namespace, _name)) kernelIntegrity public returns (bytes32 id) {
        return _setApp(_namespace, _name, _app);
    }

    /**
    * @dev Get the address of an app instance or base implementation
    * @param _id App identifier
    * @return Address of the app
    */
    function getApp(bytes32 _id) public view returns (address) {
        return apps[_id];
    }

    /**
    * @dev Get the address of the recovery Vault instance (to recover funds)
    * @return Address of the Vault
    */
    function getRecoveryVault() public view returns (address) {
        return apps[recoveryVaultId];
    }

    /**
    * @dev Set the default vault id for the escape hatch mechanism
    * @param _name Name of the app
    */
    function setRecoveryVaultId(bytes32 _name) auth(APP_MANAGER_ROLE, arr(APP_ADDR_NAMESPACE, _name)) public {
        recoveryVaultId = keccak256(APP_ADDR_NAMESPACE, _name);
    }

    /**
    * @dev Get the installed ACL app
    * @return ACL app
    */
    function acl() public view returns (IACL) {
        return IACL(getApp(ACL_APP));
    }

    /**
    * @dev Function called by apps to check ACL on kernel or to check permission status
    * @param _who Sender of the original call
    * @param _where Address of the app
    * @param _what Identifier for a group of actions in app
    * @param _how Extra data for ACL auth
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasPermission(address _who, address _where, bytes32 _what, bytes _how) public view returns (bool) {
        return acl().hasPermission(_who, _where, _what, _how);
    }

    function _setApp(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        require(isContract(_app));
        id = keccak256(_namespace, _name);
        apps[id] = _app;
        SetApp(_namespace, _name, id, _app);
    }

    function _setAppIfNew(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        require(isContract(_app));

        id = keccak256(_namespace, _name);

        address app = getApp(id);
        if (app != address(0)) {
            require(app == _app);
        } else {
            apps[id] = _app;
            SetApp(_namespace, _name, id, _app);
        }
    }

    modifier auth(bytes32 _role, uint256[] memory params) {
        bytes memory how;
        uint256 byteLength = params.length * 32;
        assembly {
            how := params // forced casting
            mstore(how, byteLength)
        }
        // Params is invalid from this point fwd
        require(hasPermission(msg.sender, address(this), _role, how));
        _;
    }

    modifier kernelIntegrity {
        _; // After execution check integrity
        address kernel = getApp(KERNEL_APP);
        uint256 size;
        assembly { size := extcodesize(kernel) }
        require(size > 0);
    }
}


///File: @aragon/os/contracts/kernel/KernelProxy.sol

pragma solidity 0.4.18;





contract KernelProxy is KernelStorage, DepositableDelegateProxy {
    /**
    * @dev KernelProxy is a proxy contract to a kernel implementation. The implementation
    *      can update the reference, which effectively upgrades the contract
    * @param _kernelImpl Address of the contract used as implementation for kernel
    */
    function KernelProxy(address _kernelImpl) public {
        apps[keccak256(CORE_NAMESPACE, KERNEL_APP_ID)] = _kernelImpl;
    }

    /**
     * @dev ERC897, whether it is a forwarding (1) or an upgradeable (2) proxy
     */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return UPGRADEABLE;
    }

    /**
    * @dev ERC897, the address the proxy would delegate calls to
    */
    function implementation() public view returns (address) {
        return apps[KERNEL_APP];
    }

}


///File: @aragon/os/contracts/evmscript/ScriptHelpers.sol

pragma solidity ^0.4.18;


library ScriptHelpers {
    // To test with JS and compare with actual encoder. Maintaining for reference.
    // t = function() { return IEVMScriptExecutor.at('0x4bcdd59d6c77774ee7317fc1095f69ec84421e49').contract.execScript.getData(...[].slice.call(arguments)).slice(10).match(/.{1,64}/g) }
    // run = function() { return ScriptHelpers.new().then(sh => { sh.abiEncode.call(...[].slice.call(arguments)).then(a => console.log(a.slice(2).match(/.{1,64}/g)) ) }) }
    // This is truly not beautiful but lets no daydream to the day solidity gets reflection features

    function abiEncode(bytes _a, bytes _b, address[] _c) public pure returns (bytes d) {
        return encode(_a, _b, _c);
    }

    function encode(bytes memory _a, bytes memory _b, address[] memory _c) internal pure returns (bytes memory d) {
        // A is positioned after the 3 position words
        uint256 aPosition = 0x60;
        uint256 bPosition = aPosition + 32 * abiLength(_a);
        uint256 cPosition = bPosition + 32 * abiLength(_b);
        uint256 length = cPosition + 32 * abiLength(_c);

        d = new bytes(length);
        assembly {
            // Store positions
            mstore(add(d, 0x20), aPosition)
            mstore(add(d, 0x40), bPosition)
            mstore(add(d, 0x60), cPosition)
        }

        // Copy memory to correct position
        copy(d, getPtr(_a), aPosition, _a.length);
        copy(d, getPtr(_b), bPosition, _b.length);
        copy(d, getPtr(_c), cPosition, _c.length * 32); // 1 word per address
    }

    function abiLength(bytes memory _a) internal pure returns (uint256) {
        // 1 for length +
        // memory words + 1 if not divisible for 32 to offset word
        return 1 + (_a.length / 32) + (_a.length % 32 > 0 ? 1 : 0);
    }

    function abiLength(address[] _a) internal pure returns (uint256) {
        // 1 for length + 1 per item
        return 1 + _a.length;
    }

    function copy(bytes _d, uint256 _src, uint256 _pos, uint256 _length) internal pure {
        uint dest;
        assembly {
            dest := add(add(_d, 0x20), _pos)
        }
        memcpy(dest, _src, _length + 32);
    }

    function getPtr(bytes memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getPtr(address[] memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getSpecId(bytes _script) internal pure returns (uint32) {
        return uint32At(_script, 0);
    }

    function uint256At(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(_data, add(0x20, _location)))
        }
    }

    function addressAt(bytes _data, uint256 _location) internal pure returns (address result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
            0x1000000000000000000000000)
        }
    }

    function uint32At(bytes _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000),
            0x100000000000000000000000000000000000000000000000000000000)
        }
    }

    function locationOf(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := add(_data, add(0x20, _location))
        }
    }

    function toBytes(bytes4 _sig) internal pure returns (bytes) {
        bytes memory payload = new bytes(4);
        assembly { mstore(add(payload, 0x20), _sig) }
        return payload;
    }

    function memcpy(uint _dest, uint _src, uint _len) internal pure {
        uint256 src = _src;
        uint256 dest = _dest;
        uint256 len = _len;

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}


///File: @aragon/os/contracts/evmscript/IEVMScriptExecutor.sol

pragma solidity ^0.4.18;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
}


///File: @aragon/os/contracts/evmscript/IEVMScriptRegistry.sol

pragma solidity ^0.4.18;


contract EVMScriptRegistryConstants {
    /* Hardcoded constants to save gas
    // repeated definitions from KernelStorage, to avoid out of gas issues
    bytes32 constant public APP_ADDR_NAMESPACE = keccak256("app");

    bytes32 constant public EVMSCRIPT_REGISTRY_APP_ID = apmNamehash("evmreg");
    bytes32 constant public EVMSCRIPT_REGISTRY_APP = keccak256(APP_ADDR_NAMESPACE, EVMSCRIPT_REGISTRY_APP_ID);
    */
    bytes32 constant public APP_ADDR_NAMESPACE = 0xd6f028ca0e8edb4a8c9757ca4fdccab25fa1e0317da1188108f7d2dee14902fb;
    bytes32 constant public EVMSCRIPT_REGISTRY_APP_ID = 0xddbcfd564f642ab5627cf68b9b7d374fb4f8a36e941a75d89c87998cef03bd61;
    bytes32 constant public EVMSCRIPT_REGISTRY_APP = 0x34f01c17e9be6ddbf2c61f37b5b1fb9f1a090a975006581ad19bda1c4d382871;
}


interface IEVMScriptRegistry {
    function addScriptExecutor(address executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    function getScriptExecutor(bytes script) public view returns (address);
}


///File: @aragon/os/contracts/evmscript/EVMScriptRunner.sol

pragma solidity ^0.4.18;








contract EVMScriptRunner is AppStorage, EVMScriptRegistryConstants {
    using ScriptHelpers for bytes;

    function runScript(bytes _script, bytes _input, address[] _blacklist) protectState internal returns (bytes output) {
        // TODO: Too much data flying around, maybe extracting spec id here is cheaper
        address executorAddr = getExecutor(_script);
        require(executorAddr != address(0));

        bytes memory calldataArgs = _script.encode(_input, _blacklist);
        bytes4 sig = IEVMScriptExecutor(0).execScript.selector;

        require(executorAddr.delegatecall(sig, calldataArgs));

        bytes memory ret = returnedDataDecoded();

        require(ret.length > 0);

        return ret;
    }

    function getExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getExecutorRegistry().getScriptExecutor(_script));
    }

    // TODO: Internal
    function getExecutorRegistry() internal view returns (IEVMScriptRegistry) {
        address registryAddr = kernel.getApp(EVMSCRIPT_REGISTRY_APP);
        return IEVMScriptRegistry(registryAddr);
    }

    /**
    * @dev copies and returns last's call data. Needs to ABI decode first
    */
    function returnedDataDecoded() internal pure returns (bytes ret) {
        assembly {
            let size := returndatasize
            switch size
            case 0 {}
            default {
                ret := mload(0x40) // free mem ptr get
                mstore(0x40, add(ret, add(size, 0x20))) // free mem ptr set
                returndatacopy(ret, 0x20, sub(size, 0x20)) // copy return data
            }
        }
        return ret;
    }

    modifier protectState {
        address preKernel = kernel;
        bytes32 preAppId = appId;
        _; // exec
        require(kernel == preKernel);
        require(appId == preAppId);
    }
}


///File: @aragon/os/contracts/apps/AragonApp.sol

pragma solidity ^0.4.18;








// ACLSyntaxSugar and EVMScriptRunner are not directly used by this contract, but are included so
// that they are automatically usable by subclassing contracts
contract AragonApp is AppStorage, Initializable, ACLSyntaxSugar, VaultRecoverable, EVMScriptRunner {
    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)));
        _;
    }

    modifier authP(bytes32 _role, uint256[] params) {
        require(canPerform(msg.sender, _role, params));
        _;
    }

    function canPerform(address _sender, bytes32 _role, uint256[] params) public view returns (bool) {
        bytes memory how; // no need to init memory as it is never used
        if (params.length > 0) {
            uint256 byteLength = params.length * 32;
            assembly {
                how := params // forced casting
                mstore(how, byteLength)
            }
        }
        return address(kernel) == 0 || kernel.hasPermission(_sender, address(this), _role, how);
    }

    function getRecoveryVault() public view returns (address) {
        // Funds recovery via a vault is only available when used with a kernel
        require(address(kernel) != 0);
        return kernel.getRecoveryVault();
    }
}


///File: @aragon/os/contracts/acl/ACL.sol

pragma solidity 0.4.18;






interface ACLOracle {
    function canPerform(address who, address where, bytes32 what, uint256[] how) public view returns (bool);
}


contract ACL is IACL, AragonApp, ACLHelpers {
    // Hardcoded constant to save gas
    //bytes32 constant public CREATE_PERMISSIONS_ROLE = keccak256("CREATE_PERMISSIONS_ROLE");
    bytes32 constant public CREATE_PERMISSIONS_ROLE = 0x0b719b33c83b8e5d300c521cb8b54ae9bd933996a14bef8c2f4e0285d2d2400a;

    // whether a certain entity has a permission
    mapping (bytes32 => bytes32) permissions; // 0 for no permission, or parameters id
    mapping (bytes32 => Param[]) public permissionParams;

    // who is the manager of a permission
    mapping (bytes32 => address) permissionManager;

    enum Op { NONE, EQ, NEQ, GT, LT, GTE, LTE, RET, NOT, AND, OR, XOR, IF_ELSE } // op types

    struct Param {
        uint8 id;
        uint8 op;
        uint240 value; // even though value is an uint240 it can store addresses
        // in the case of 32 byte hashes losing 2 bytes precision isn't a huge deal
        // op and id take less than 1 byte each so it can be kept in 1 sstore
    }

    uint8 constant BLOCK_NUMBER_PARAM_ID = 200;
    uint8 constant TIMESTAMP_PARAM_ID    = 201;
    uint8 constant SENDER_PARAM_ID       = 202;
    uint8 constant ORACLE_PARAM_ID       = 203;
    uint8 constant LOGIC_OP_PARAM_ID     = 204;
    uint8 constant PARAM_VALUE_PARAM_ID  = 205;
    // TODO: Add execution times param type?

    // Hardcoded constant to save gas
    //bytes32 constant public EMPTY_PARAM_HASH = keccak256(uint256(0));
    bytes32 constant public EMPTY_PARAM_HASH = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;
    address constant ANY_ENTITY = address(-1);

    modifier onlyPermissionManager(address _app, bytes32 _role) {
        require(msg.sender == getPermissionManager(_app, _role));
        _;
    }

    event SetPermission(address indexed entity, address indexed app, bytes32 indexed role, bool allowed);
    event ChangePermissionManager(address indexed app, bytes32 indexed role, address indexed manager);

    /**
    * @dev Initialize can only be called once. It saves the block number in which it was initialized.
    * @notice Initializes an ACL instance and sets `_permissionsCreator` as the entity that can create other permissions
    * @param _permissionsCreator Entity that will be given permission over createPermission
    */
    function initialize(address _permissionsCreator) onlyInit public {
        initialized();
        require(msg.sender == address(kernel));

        _createPermission(_permissionsCreator, this, CREATE_PERMISSIONS_ROLE, _permissionsCreator);
    }

    /**
    * @dev Creates a permission that wasn't previously set and managed. Access is limited by the ACL.
    *      If a created permission is removed it is possible to reset it with createPermission.
    * @notice Create a new permission granting `_entity` the ability to perform actions of role `_role` on `_app` (setting `_manager` as the permission manager)
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _manager Address of the entity that will be able to grant and revoke the permission further.
    */
    function createPermission(address _entity, address _app, bytes32 _role, address _manager) external {
        require(hasPermission(msg.sender, address(this), CREATE_PERMISSIONS_ROLE));

        _createPermission(_entity, _app, _role, _manager);
    }

    /**
    * @dev Grants permission if allowed. This requires `msg.sender` to be the permission manager
    * @notice Grants `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    */
    function grantPermission(address _entity, address _app, bytes32 _role)
        external
    {
        grantPermissionP(_entity, _app, _role, new uint256[](0));
    }

    /**
    * @dev Grants a permission with parameters if allowed. This requires `msg.sender` to be the permission manager
    * @notice Grants `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app in which the role will be allowed (requires app to depend on kernel for ACL)
    * @param _role Identifier for the group of actions in app given access to perform
    * @param _params Permission parameters
    */
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] _params)
        onlyPermissionManager(_app, _role)
        public
    {
        bytes32 paramsHash = _params.length > 0 ? _saveParams(_params) : EMPTY_PARAM_HASH;
        _setPermission(_entity, _app, _role, paramsHash);
    }

    /**
    * @dev Revokes permission if allowed. This requires `msg.sender` to be the the permission manager
    * @notice Revokes `_entity` the ability to perform actions of role `_role` on `_app`
    * @param _entity Address of the whitelisted entity to revoke access from
    * @param _app Address of the app in which the role will be revoked
    * @param _role Identifier for the group of actions in app being revoked
    */
    function revokePermission(address _entity, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        _setPermission(_entity, _app, _role, bytes32(0));
    }

    /**
    * @notice Sets `_newManager` as the manager of the permission `_role` in `_app`
    * @param _newManager Address for the new manager
    * @param _app Address of the app in which the permission management is being transferred
    * @param _role Identifier for the group of actions being transferred
    */
    function setPermissionManager(address _newManager, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        _setPermissionManager(_newManager, _app, _role);
    }

    /**
    * @notice Removes the manager of the permission `_role` in `_app`
    * @param _app Address of the app in which the permission is being unmanaged
    * @param _role Identifier for the group of actions being unmanaged
    */
    function removePermissionManager(address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        _setPermissionManager(address(0), _app, _role);
    }

    /**
     * @notice Get parameters for permission array length
     * @param _entity Address of the whitelisted entity that will be able to perform the role
     * @param _app Address of the app
     * @param _role Identifier for a group of actions in app
     * @return Length of the array
     */
    function getPermissionParamsLength(address _entity, address _app, bytes32 _role) external view returns (uint) {
        return permissionParams[permissions[permissionHash(_entity, _app, _role)]].length;
    }

    /**
    * @notice Get parameter for permission
    * @param _entity Address of the whitelisted entity that will be able to perform the role
    * @param _app Address of the app
    * @param _role Identifier for a group of actions in app
    * @param _index Index of parameter in the array
    * @return Parameter (id, op, value)
    */
    function getPermissionParam(address _entity, address _app, bytes32 _role, uint _index) external view returns (uint8 id, uint8 op, uint240 value) {
        Param storage param = permissionParams[permissions[permissionHash(_entity, _app, _role)]][_index];
        id = param.id;
        op = param.op;
        value = param.value;
    }

    /**
    * @dev Get manager for permission
    * @param _app Address of the app
    * @param _role Identifier for a group of actions in app
    * @return address of the manager for the permission
    */
    function getPermissionManager(address _app, bytes32 _role) public view returns (address) {
        return permissionManager[roleHash(_app, _role)];
    }

    /**
    * @dev Function called by apps to check ACL on kernel or to check permission statu
    * @param _who Sender of the original call
    * @param _where Address of the app
    * @param _where Identifier for a group of actions in app
    * @param _how Permission parameters
    * @return boolean indicating whether the ACL allows the role or not
    */
    function hasPermission(address _who, address _where, bytes32 _what, bytes memory _how) public view returns (bool) {
        uint256[] memory how;
        uint256 intsLength = _how.length / 32;
        assembly {
            how := _how // forced casting
            mstore(how, intsLength)
        }
        // _how is invalid from this point fwd
        return hasPermission(_who, _where, _what, how);
    }

    function hasPermission(address _who, address _where, bytes32 _what, uint256[] memory _how) public view returns (bool) {
        bytes32 whoParams = permissions[permissionHash(_who, _where, _what)];
        if (whoParams != bytes32(0) && evalParams(whoParams, _who, _where, _what, _how)) {
            return true;
        }

        bytes32 anyParams = permissions[permissionHash(ANY_ENTITY, _where, _what)];
        if (anyParams != bytes32(0) && evalParams(anyParams, ANY_ENTITY, _where, _what, _how)) {
            return true;
        }

        return false;
    }

    function hasPermission(address _who, address _where, bytes32 _what) public view returns (bool) {
        uint256[] memory empty = new uint256[](0);
        return hasPermission(_who, _where, _what, empty);
    }

    function evalParams(
        bytes32 _paramsHash,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) public view returns (bool)
    {
        if (_paramsHash == EMPTY_PARAM_HASH) {
            return true;
        }

        return evalParam(_paramsHash, 0, _who, _where, _what, _how);
    }

    /**
    * @dev Internal createPermission for access inside the kernel (on instantiation)
    */
    function _createPermission(address _entity, address _app, bytes32 _role, address _manager) internal {
        // only allow permission creation (or re-creation) when there is no manager
        require(getPermissionManager(_app, _role) == address(0));

        _setPermission(_entity, _app, _role, EMPTY_PARAM_HASH);
        _setPermissionManager(_manager, _app, _role);
    }

    /**
    * @dev Internal function called to actually save the permission
    */
    function _setPermission(address _entity, address _app, bytes32 _role, bytes32 _paramsHash) internal {
        permissions[permissionHash(_entity, _app, _role)] = _paramsHash;

        SetPermission(_entity, _app, _role, _paramsHash != bytes32(0));
    }

    function _saveParams(uint256[] _encodedParams) internal returns (bytes32) {
        bytes32 paramHash = keccak256(_encodedParams);
        Param[] storage params = permissionParams[paramHash];

        if (params.length == 0) { // params not saved before
            for (uint256 i = 0; i < _encodedParams.length; i++) {
                uint256 encodedParam = _encodedParams[i];
                Param memory param = Param(decodeParamId(encodedParam), decodeParamOp(encodedParam), uint240(encodedParam));
                params.push(param);
            }
        }

        return paramHash;
    }

    function evalParam(
        bytes32 _paramsHash,
        uint32 _paramId,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) internal view returns (bool)
    {
        if (_paramId >= permissionParams[_paramsHash].length) {
            return false; // out of bounds
        }

        Param memory param = permissionParams[_paramsHash][_paramId];

        if (param.id == LOGIC_OP_PARAM_ID) {
            return evalLogic(param, _paramsHash, _who, _where, _what, _how);
        }

        uint256 value;
        uint256 comparedTo = uint256(param.value);

        // get value
        if (param.id == ORACLE_PARAM_ID) {
            value = checkOracle(address(param.value), _who, _where, _what, _how) ? 1 : 0;
            comparedTo = 1;
        } else if (param.id == BLOCK_NUMBER_PARAM_ID) {
            value = blockN();
        } else if (param.id == TIMESTAMP_PARAM_ID) {
            value = time();
        } else if (param.id == SENDER_PARAM_ID) {
            value = uint256(msg.sender);
        } else if (param.id == PARAM_VALUE_PARAM_ID) {
            value = uint256(param.value);
        } else {
            if (param.id >= _how.length) {
                return false;
            }
            value = uint256(uint240(_how[param.id])); // force lost precision
        }

        if (Op(param.op) == Op.RET) {
            return uint256(value) > 0;
        }

        return compare(value, Op(param.op), comparedTo);
    }

    function evalLogic(Param _param, bytes32 _paramsHash, address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
        if (Op(_param.op) == Op.IF_ELSE) {
            var (condition, success, failure) = decodeParamsList(uint256(_param.value));
            bool result = evalParam(_paramsHash, condition, _who, _where, _what, _how);

            return evalParam(_paramsHash, result ? success : failure, _who, _where, _what, _how);
        }

        var (v1, v2,) = decodeParamsList(uint256(_param.value));
        bool r1 = evalParam(_paramsHash, v1, _who, _where, _what, _how);

        if (Op(_param.op) == Op.NOT) {
            return !r1;
        }

        if (r1 && Op(_param.op) == Op.OR) {
            return true;
        }

        if (!r1 && Op(_param.op) == Op.AND) {
            return false;
        }

        bool r2 = evalParam(_paramsHash, v2, _who, _where, _what, _how);

        if (Op(_param.op) == Op.XOR) {
            return r1 != r2;
        }

        return r2; // both or and and depend on result of r2 after checks
    }

    function compare(uint256 _a, Op _op, uint256 _b) internal pure returns (bool) {
        if (_op == Op.EQ)  return _a == _b;                              // solium-disable-line lbrace
        if (_op == Op.NEQ) return _a != _b;                              // solium-disable-line lbrace
        if (_op == Op.GT)  return _a > _b;                               // solium-disable-line lbrace
        if (_op == Op.LT)  return _a < _b;                               // solium-disable-line lbrace
        if (_op == Op.GTE) return _a >= _b;                              // solium-disable-line lbrace
        if (_op == Op.LTE) return _a <= _b;                              // solium-disable-line lbrace
        return false;
    }

    function checkOracle(address _oracleAddr, address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
        bytes4 sig = ACLOracle(_oracleAddr).canPerform.selector;

        // a raw call is required so we can return false if the call reverts, rather than reverting
        bool ok = _oracleAddr.call(sig, _who, _where, _what, 0x80, _how.length, _how);
        // 0x80 is the position where the array that goes there starts

        if (!ok) {
            return false;
        }

        uint256 size;
        assembly { size := returndatasize }
        if (size != 32) {
            return false;
        }

        bool result;
        assembly {
            let ptr := mload(0x40)       // get next free memory ptr
            returndatacopy(ptr, 0, size) // copy return from above `call`
            result := mload(ptr)         // read data at ptr and set it to result
            mstore(ptr, 0)               // set pointer memory to 0 so it still is the next free ptr
        }

        return result;
    }

    /**
    * @dev Internal function that sets management
    */
    function _setPermissionManager(address _newManager, address _app, bytes32 _role) internal {
        permissionManager[roleHash(_app, _role)] = _newManager;
        ChangePermissionManager(_app, _role, _newManager);
    }

    function roleHash(address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(1), _where, _what);
    }

    function permissionHash(address _who, address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(2), _who, _where, _what);
    }

    function time() internal view returns (uint64) { return uint64(block.timestamp); } // solium-disable-line security/no-block-members

    function blockN() internal view returns (uint256) { return block.number; }
}


///File: @aragon/os/contracts/evmscript/EVMScriptRegistry.sol

pragma solidity 0.4.18;








contract EVMScriptRegistry is IEVMScriptRegistry, EVMScriptRegistryConstants, AragonApp {
    using ScriptHelpers for bytes;

    // WARN: Manager can censor all votes and the like happening in an org
    // bytes32 constant public REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");
    bytes32 constant public REGISTRY_MANAGER_ROLE = 0xf7a450ef335e1892cb42c8ca72e7242359d7711924b75db5717410da3f614aa3;

    struct ExecutorEntry {
        address executor;
        bool enabled;
    }

    ExecutorEntry[] public executors;

    function initialize() onlyInit public {
        initialized();
        // Create empty record to begin executor IDs at 1
        executors.push(ExecutorEntry(address(0), false));
    }

    function addScriptExecutor(address _executor) external auth(REGISTRY_MANAGER_ROLE) returns (uint id) {
        return executors.push(ExecutorEntry(_executor, true));
    }

    function disableScriptExecutor(uint256 _executorId) external auth(REGISTRY_MANAGER_ROLE) {
        executors[_executorId].enabled = false;
    }

    function getScriptExecutor(bytes _script) public view returns (address) {
        uint256 id = _script.getSpecId();

        if (id == 0 || id >= executors.length) {
            return address(0);
        }

        ExecutorEntry storage entry = executors[id];
        return entry.enabled ? entry.executor : address(0);
    }
}


///File: @aragon/os/contracts/evmscript/executors/CallsScript.sol

pragma solidity 0.4.18;

// Inspired by https://github.com/reverendus/tx-manager





contract CallsScript is IEVMScriptExecutor {
    using ScriptHelpers for bytes;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

    event LogScriptCall(address indexed sender, address indexed src, address indexed dst);

    /**
    * @notice Executes a number of call scripts
    * @param _script [ specId (uint32) ] many calls with this structure ->
    *    [ to (address: 20 bytes) ] [ calldataLength (uint32: 4 bytes) ] [ calldata (calldataLength bytes) ]
    * @param _input Input is ignored in callscript
    * @param _blacklist Addresses the script cannot call to, or will revert.
    * @return always returns empty byte array
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        uint256 location = SCRIPT_START_LOCATION; // first 32 bits are spec id
        while (location < _script.length) {
            address contractAddress = _script.addressAt(location);
            // Check address being called is not blacklist
            for (uint i = 0; i < _blacklist.length; i++) {
                require(contractAddress != _blacklist[i]);
            }

            // logged before execution to ensure event ordering in receipt
            // if failed entire execution is reverted regardless
            LogScriptCall(msg.sender, address(this), contractAddress);

            uint256 calldataLength = uint256(_script.uint32At(location + 0x14));
            uint256 startOffset = location + 0x14 + 0x04;
            uint256 calldataStart = _script.locationOf(startOffset);

            // compute end of script / next location
            location = startOffset + calldataLength;
            require(location <= _script.length);

            assembly {
                let success := call(sub(gas, 5000), contractAddress, 0, calldataStart, calldataLength, 0, 0)
                switch success case 0 { revert(0, 0) }
            }
        }

        bytes memory ret = new bytes(1);
        ret[0] = 0x01;

        return ret;
    }
}


///File: @aragon/os/contracts/evmscript/executors/DelegateScript.sol

pragma solidity 0.4.18;






interface DelegateScriptTarget {
    function exec() public returns (bool);
}


contract DelegateScript is IEVMScriptExecutor, IsContract {
    using ScriptHelpers for *;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

    /**
    * @notice Executes script by delegatecall into a contract
    * @param _script [ specId (uint32) ][ contract address (20 bytes) ]
    * @param _input ABI encoded call to be made to contract (if empty executes default exec() function)
    * @param _blacklist If any address is passed, will revert.
    * @return Call return data
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0); // dont have ability to control bans, so fail.

        // Script should be spec id + address (20 bytes)
        require(_script.length == SCRIPT_START_LOCATION + 20);
        return delegate(_script.addressAt(SCRIPT_START_LOCATION), _input);
    }

    /**
    * @dev Delegatecall to contract with input data
    */
    function delegate(address _addr, bytes memory _input) internal returns (bytes memory output) {
        require(isContract(_addr));
        require(_addr.delegatecall(_input.length > 0 ? _input : defaultInput()));
        bytes memory ret = returnedData();

        require(ret.length > 0);

        return ret;
    }

    function defaultInput() internal pure returns (bytes) {
        return DelegateScriptTarget(0).exec.selector.toBytes();
    }

    /**
    * @dev copies and returns last's call data
    */
    function returnedData() internal pure returns (bytes ret) {
        assembly {
            let size := returndatasize
            ret := mload(0x40) // free mem ptr get
            mstore(0x40, add(ret, add(size, 0x20))) // free mem ptr set
            mstore(ret, size) // set array length
            returndatacopy(add(ret, 0x20), 0, size) // copy return data
        }
        return ret;
    }
}


///File: @aragon/os/contracts/evmscript/executors/DeployDelegateScript.sol

pragma solidity 0.4.18;



// Inspired by: https://github.com/dapphub/ds-proxy/blob/master/src/proxy.sol


contract DeployDelegateScript is DelegateScript {
    uint256 constant internal SCRIPT_START_LOCATION = 4;

    uint256[2**254] private cacheStorageOffset;
    mapping (bytes32 => address) cache;

    /**
    * @notice Executes script by delegatecall into a deployed contract (exec() function)
    * @param _script [ specId (uint32) ][ contractInitcode (bytecode) ]
    * @param _input ABI encoded call to be made to contract (if empty executes default exec() function)
    * @param _blacklist If any address is passed, will revert.
    * @return Call return data
    */
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0); // dont have ability to control bans, so fail.

        bytes32 id = keccak256(_script);
        address deployed = cache[id];
        if (deployed == address(0)) {
            deployed = deploy(_script);
            cache[id] = deployed;
        }

        return DelegateScript.delegate(deployed, _input);
    }

    /**
    * @dev Deploys contract byte code to network
    */
    function deploy(bytes _script) internal returns (address addr) {
        assembly {
            // 0x24 = 0x20 (length) + 0x04 (spec id uint32)
            // Length of code is 4 bytes less than total script size
            addr := create(0, add(_script, 0x24), sub(mload(_script), 0x04))
            switch iszero(extcodesize(addr))
            case 1 { revert(0, 0) } // throw if contract failed to deploy
        }
    }
}


///File: @aragon/os/contracts/factory/EVMScriptRegistryFactory.sol

pragma solidity 0.4.18;












contract EVMScriptRegistryFactory is AppProxyFactory, EVMScriptRegistryConstants {
    address public baseReg;
    address public baseCalls;
    address public baseDel;
    address public baseDeployDel;

    function EVMScriptRegistryFactory() public {
        baseReg = address(new EVMScriptRegistry());
        baseCalls = address(new CallsScript());
        baseDel = address(new DelegateScript());
        baseDeployDel = address(new DeployDelegateScript());
    }

    function newEVMScriptRegistry(Kernel _dao, address _root) public returns (EVMScriptRegistry reg) {
        reg = EVMScriptRegistry(_dao.newPinnedAppInstance(EVMSCRIPT_REGISTRY_APP_ID, baseReg, true));
        reg.initialize();

        ACL acl = ACL(_dao.acl());

        acl.createPermission(this, reg, reg.REGISTRY_MANAGER_ROLE(), this);

        reg.addScriptExecutor(baseCalls);     // spec 1 = CallsScript
        reg.addScriptExecutor(baseDel);       // spec 2 = DelegateScript
        reg.addScriptExecutor(baseDeployDel); // spec 3 = DeployDelegateScript

        acl.revokePermission(this, reg, reg.REGISTRY_MANAGER_ROLE());
        acl.setPermissionManager(_root, reg, reg.REGISTRY_MANAGER_ROLE());

        return reg;
    }
}


///File: @aragon/os/contracts/factory/DAOFactory.sol

pragma solidity 0.4.18;









contract DAOFactory {
    address public baseKernel;
    address public baseACL;
    EVMScriptRegistryFactory public regFactory;

    event DeployDAO(address dao);
    event DeployEVMScriptRegistry(address reg);

    function DAOFactory(address _baseKernel, address _baseACL, address _regFactory) public {
        // No need to init as it cannot be killed by devops199
        if (_regFactory != address(0)) {
            regFactory = EVMScriptRegistryFactory(_regFactory);
        }

        baseKernel = _baseKernel;
        baseACL = _baseACL;
    }

    /**
    * @param _root Address that will be granted control to setup DAO permissions
    */
    function newDAO(address _root) public returns (Kernel dao) {
        dao = Kernel(new KernelProxy(baseKernel));

        if (address(regFactory) == address(0)) {
            dao.initialize(baseACL, _root);
        } else {
            dao.initialize(baseACL, this);

            ACL acl = ACL(dao.acl());
            bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();
            bytes32 appManagerRole = dao.APP_MANAGER_ROLE();

            acl.grantPermission(regFactory, acl, permRole);

            acl.createPermission(regFactory, dao, appManagerRole, this);

            EVMScriptRegistry reg = regFactory.newEVMScriptRegistry(dao, _root);
            DeployEVMScriptRegistry(address(reg));

            acl.revokePermission(regFactory, dao, appManagerRole);
            acl.revokePermission(regFactory, acl, permRole);
            acl.revokePermission(this, acl, permRole);
            acl.grantPermission(_root, acl, permRole);

            acl.removePermissionManager(dao, appManagerRole);
            acl.setPermissionManager(_root, acl, permRole);
        }

        DeployDAO(dao);
    }
}


///File: ./contracts/LiquidPledgingACLHelpers.sol

pragma solidity ^0.4.18;

contract LiquidPledgingACLHelpers {
    function arr(uint64 a, uint64 b, address c, uint d, address e) internal pure returns(uint[] r) {
        r = new uint[](4);
        r[0] = uint(a);
        r[1] = uint(b);
        r[2] = uint(c);
        r[3] = d;
        r[4] = uint(e);
    }

    function arr(bool a) internal pure returns (uint[] r) {
        r = new uint[](1);
        uint _a;
        assembly {
            _a := a // forced casting
        }
        r[0] = _a;
    }
}

///File: ./contracts/LPVault.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina
    Contributors: RJ Ewing, Griff Green, Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/// @dev This contract holds ether securely for liquid pledging systems; for
///  this iteration the funds will come often be escaped to the Giveth Multisig
///  (safety precaution), but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escapeHatch to be implemented in case of issues;
///  future versions of this contract will be enabled for tokens



/// @dev `LiquidPledging` is a basic interface to allow the `LPVault` contract
///  to confirm and cancel payments in the `LiquidPledging` contract.
contract ILiquidPledging {
    function confirmPayment(uint64 idPledge, uint amount) public;
    function cancelPayment(uint64 idPledge, uint amount) public;
}

/// @dev `LPVault` is a higher level contract built off of the `Escapable`
///  contract that holds funds for the liquid pledging system.
contract LPVault is AragonApp, LiquidPledgingACLHelpers {

    bytes32 constant public CONFIRM_PAYMENT_ROLE = keccak256("CONFIRM_PAYMENT_ROLE");
    bytes32 constant public CANCEL_PAYMENT_ROLE = keccak256("CANCEL_PAYMENT_ROLE");
    bytes32 constant public SET_AUTOPAY_ROLE = keccak256("SET_AUTOPAY_ROLE");
    bytes32 constant public ESCAPE_HATCH_CALLER_ROLE = keccak256("ESCAPE_HATCH_CALLER_ROLE");

    event AutoPaySet(bool autoPay);
    event EscapeFundsCalled(address token, uint amount);
    event ConfirmPayment(uint indexed idPayment, bytes32 indexed ref);
    event CancelPayment(uint indexed idPayment, bytes32 indexed ref);
    event AuthorizePayment(
        uint indexed idPayment,
        bytes32 indexed ref,
        address indexed dest,
        address token,
        uint amount
    );

    enum PaymentStatus {
        Pending, // When the payment is awaiting confirmation
        Paid,    // When the payment has been sent
        Canceled // When the payment will never be sent
    }

    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment the `ref` param makes it easy to track the movements of
    ///  funds transparently by its connection to other `Payment` structs
    struct Payment {
        bytes32 ref; // an input that references details from other contracts
        address dest; // recipient of the ETH
        PaymentStatus state; // Pending, Paid or Canceled
        address token;
        uint amount; // amount of ETH (in wei) to be sent
    }

    bool public autoPay; // If false, payments will take 2 txs to be completed

    // @dev An array that contains all the payments for this LPVault
    Payment[] public payments;
    ILiquidPledging public liquidPledging;

    /// @dev The attached `LiquidPledging` contract is the only address that can
    ///  call a function with this modifier
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }

    /// @param _liquidPledging Address of the liquidPledging instance associated
    /// with this LPVault
    function initialize(address _liquidPledging) onlyInit external {
        require(_liquidPledging != 0x0);
        initialized();

        liquidPledging = ILiquidPledging(_liquidPledging);
    }

    /// @notice Used to decentralize, toggles whether the LPVault will
    ///  automatically confirm a payment after the payment has been authorized
    /// @param _automatic If true, payments will confirm instantly, if false
    ///  the training wheels are put on and the owner must manually approve 
    ///  every payment
    function setAutopay(bool _automatic) external authP(SET_AUTOPAY_ROLE, arr(_automatic)) {
        autoPay = _automatic;
        AutoPaySet(autoPay);
    }

    /// @notice If `autoPay == true` the transfer happens automatically `else` the `owner`
    ///  must call `confirmPayment()` for a transfer to occur (training wheels);
    ///  either way, a new payment is added to `payments[]` 
    /// @param _ref References the payment will normally be the pledgeID
    /// @param _dest The address that payments will be sent to
    /// @param _amount The amount that the payment is being authorized for
    /// @return idPayment The id of the payment (needed by the owner to confirm)
    function authorizePayment(
        bytes32 _ref,
        address _dest,
        address _token,
        uint _amount
    ) external onlyLiquidPledging returns (uint)
    {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentStatus.Pending;
        payments[idPayment].ref = _ref;
        payments[idPayment].dest = _dest;
        payments[idPayment].token = _token;
        payments[idPayment].amount = _amount;

        AuthorizePayment(idPayment, _ref, _dest, _token, _amount);

        if (autoPay) {
            _doConfirmPayment(idPayment);
        }

        return idPayment;
    }

    /// @notice Allows the owner to confirm payments;  since 
    ///  `authorizePayment` is the only way to populate the `payments[]` array
    ///  this is generally used when `autopay` is `false` after a payment has
    ///  has been authorized
    /// @param _idPayment Array lookup for the payment.
    function confirmPayment(uint _idPayment) public {
        Payment storage p = payments[_idPayment];
        require(canPerform(msg.sender, CONFIRM_PAYMENT_ROLE, arr(_idPayment, p.amount)));
        _doConfirmPayment(_idPayment);
    }

    /// @notice When `autopay` is `false` and after a payment has been authorized
    ///  to allow the owner to cancel a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.
    function cancelPayment(uint _idPayment) external {
        _doCancelPayment(_idPayment);
    }

    /// @notice `onlyOwner` An efficient way to confirm multiple payments
    /// @param _idPayments An array of multiple payment ids
    function multiConfirm(uint[] _idPayments) external {
        for (uint i = 0; i < _idPayments.length; i++) {
            confirmPayment(_idPayments[i]);
        }
    }

    /// @notice `onlyOwner` An efficient way to cancel multiple payments
    /// @param _idPayments An array of multiple payment ids
    function multiCancel(uint[] _idPayments) external {
        for (uint i = 0; i < _idPayments.length; i++) {
            _doCancelPayment(_idPayments[i]);
        }
    }

    /**
    * @dev By default, AragonApp will allow anyone to call transferToVault
    *      Because this app is designed to hold funds, we only want to call
    *      transferToVault in the case of an emergency. Only senders with the
    *      ESCAPE_HATCH_CALLER_ROLE are allowed to pull the "escapeHatch"
    * @param token Token address that would be recovered
    * @return bool whether the app allows the recovery
    */
    function allowRecoverability(address token) public view returns (bool) {
        return canPerform(msg.sender, ESCAPE_HATCH_CALLER_ROLE, arr(token));
    }

    /// @return The total number of payments that have ever been authorized
    function nPayments() external view returns (uint) {
        return payments.length;
    }

    /// @notice Transfers ETH according to the data held within the specified
    ///  payment id (internal function)
    /// @param _idPayment id number for the payment about to be fulfilled 
    function _doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        // transfer token or eth
        if (p.token == ETH) {
            require(this.balance >= p.amount);
            p.dest.transfer(p.amount);  // Transfers ETH denominated in wei
        } else {
            ERC20 token = ERC20(p.token);
            require(token.transfer(p.dest, p.amount)); // Transfers token to dest            
        }


        ConfirmPayment(_idPayment, p.ref);
    }

    /// @notice Cancels a pending payment (internal function)
    /// @param _idPayment id number for the payment    
    function _doCancelPayment(uint _idPayment) internal authP(CANCEL_PAYMENT_ROLE, arr(_idPayment)) {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment, p.ref);
    }

    /// @dev The fall back function allows ETH to be deposited into the LPVault
    ///  through a simple send
    function () public payable {}    
}


///File: ./contracts/ILiquidPledgingPlugin.sol

pragma solidity ^0.4.0;

/*
    Copyright 2018, Jordi Baylina
    Contributors: Adrià Massanet <adria@codecontext.io>, RJ Ewing, Griff
    Green, Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/


/// @dev `ILiquidPledgingPlugin` is the basic interface for any
///  liquid pledging plugin
contract ILiquidPledgingPlugin {

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated before a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    /// @param amount The amount of value that will be transfered.
    function beforeTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        address token,
        uint amount ) public returns (uint maxAllowed);

    /// @notice Plugins are used (much like web hooks) to initiate an action
    ///  upon any donation, delegation, or transfer; this is an optional feature
    ///  and allows for extreme customization of the contract. This function
    ///  implements any action that should be initiated after a transfer.
    /// @param pledgeManager The admin or current manager of the pledge
    /// @param pledgeFrom This is the Id from which value will be transfered.
    /// @param pledgeTo This is the Id that value will be transfered to.    
    /// @param context The situation that is triggering the plugin:
    ///  0 -> Plugin for the owner transferring pledge to another party
    ///  1 -> Plugin for the first delegate transferring pledge to another party
    ///  2 -> Plugin for the second delegate transferring pledge to another party
    ///  ...
    ///  255 -> Plugin for the intendedProject transferring pledge to another party
    ///
    ///  256 -> Plugin for the owner receiving pledge to another party
    ///  257 -> Plugin for the first delegate receiving pledge to another party
    ///  258 -> Plugin for the second delegate receiving pledge to another party
    ///  ...
    ///  511 -> Plugin for the intendedProject receiving pledge to another party
    ///  @param amount The amount of value that will be transfered.
    function afterTransfer(
        uint64 pledgeManager,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        address token,
        uint amount
    ) public;
}


///File: ./contracts/LiquidPledgingStorage.sol

pragma solidity ^0.4.18;



/// @dev This is an interface for `LPVault` which serves as a secure storage for
///  the ETH that backs the Pledges, only after `LiquidPledging` authorizes
///  payments can Pledges be converted for ETH
interface ILPVault {
    function authorizePayment(bytes32 _ref, address _dest, address _token, uint _amount) public;
    function () public payable;
}

/// This contract contains all state variables used in LiquidPledging contracts
/// This is done to have everything in 1 location, b/c state variable layout
/// is MUST have be the same when performing an upgrade.
contract LiquidPledgingStorage {
    enum PledgeAdminType { Giver, Delegate, Project }
    enum PledgeState { Pledged, Paying, Paid }

    /// @dev This struct defines the details of a `PledgeAdmin` which are 
    ///  commonly referenced by their index in the `admins` array
    ///  and can own pledges and act as delegates
    struct PledgeAdmin { 
        PledgeAdminType adminType; // Giver, Delegate or Project
        address addr; // Account or contract address for admin
        uint64 commitTime;  // In seconds, used for time Givers' & Delegates' have to veto
        uint64 parentProject;  // Only for projects
        bool canceled;      //Always false except for canceled projects

        /// @dev if the plugin is 0x0 then nothing happens, if its an address
        // than that smart contract is called when appropriate
        ILiquidPledgingPlugin plugin; 
        string name;
        string url;  // Can be IPFS hash
    }

    struct Pledge {
        uint amount;
        uint64[] delegationChain; // List of delegates in order of authority
        uint64 owner; // PledgeAdmin
        uint64 intendedProject; // Used when delegates are sending to projects
        uint64 commitTime;  // When the intendedProject will become the owner
        uint64 oldPledge; // Points to the id that this Pledge was derived from
        address token;
        PledgeState pledgeState; //  Pledged, Paying, Paid
    }

    PledgeAdmin[] admins; //The list of pledgeAdmins 0 means there is no admin
    Pledge[] pledges;
    /// @dev this mapping allows you to search for a specific pledge's 
    ///  index number by the hash of that pledge
    mapping (bytes32 => uint64) hPledge2idx;

    // this whitelist is for non-proxied plugins
    mapping (bytes32 => bool) pluginContractWhitelist;
    // this whitelist is for proxied plugins
    mapping (address => bool) pluginInstanceWhitelist;
    bool public whitelistDisabled = false;

    ILPVault public vault;

    // reserve 50 slots for future upgrades.
    uint[50] private storageOffset;
}

///File: ./contracts/LiquidPledgingPlugins.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
                  Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/





contract LiquidPledgingPlugins is AragonApp, LiquidPledgingStorage, LiquidPledgingACLHelpers {

    bytes32 constant public PLUGIN_MANAGER_ROLE = keccak256("PLUGIN_MANAGER_ROLE");

    /**
    * @dev adds an instance of a plugin to the whitelist
    */
    function addValidPluginInstance(address addr) auth(PLUGIN_MANAGER_ROLE) external {
        pluginInstanceWhitelist[addr] = true;
    }

    /**
    * @dev add a contract to the plugin whitelist.
    * @notice Proxy contracts should never be added using this method. Each individual
    *         proxy instance should be added by calling `addValidPluginInstance`
    */
    function addValidPluginContract(bytes32 contractHash) auth(PLUGIN_MANAGER_ROLE) public {
        pluginContractWhitelist[contractHash] = true;
    }

    function addValidPluginContracts(bytes32[] contractHashes) external auth(PLUGIN_MANAGER_ROLE) {
        for (uint8 i = 0; i < contractHashes.length; i++) {
            addValidPluginContract(contractHashes[i]);
        }
    }

    /**
    * @dev removes a contract from the plugin whitelist
    */
    function removeValidPluginContract(bytes32 contractHash) external authP(PLUGIN_MANAGER_ROLE, arr(contractHash)) {
        pluginContractWhitelist[contractHash] = false;
    }

    /**
    * @dev removes an instance of a plugin to the whitelist
    */
    function removeValidPluginInstance(address addr) external authP(PLUGIN_MANAGER_ROLE, arr(addr)) {
        pluginInstanceWhitelist[addr] = false;
    }

    /**
    * @dev enable/disable the plugin whitelist.
    * @notice you better know what you're doing if you are going to disable it
    */
    function useWhitelist(bool useWhitelist) external auth(PLUGIN_MANAGER_ROLE) {
        whitelistDisabled = !useWhitelist;
    }

    /**
    * check if the contract at the provided address is in the plugin whitelist
    */
    function isValidPlugin(address addr) public view returns(bool) {
        if (whitelistDisabled || addr == 0x0) {
            return true;
        }

        // first check pluginInstances
        if (pluginInstanceWhitelist[addr]) {
            return true;
        }

        // if the addr isn't a valid instance, check the contract code
        bytes32 contractHash = getCodeHash(addr);

        return pluginContractWhitelist[contractHash];
    }

    /**
    * @return the hash of the code for the given address
    */
    function getCodeHash(address addr) public view returns(bytes32) {
        bytes memory o_code;
        assembly {
            // retrieve the size of the code
            let size := extcodesize(addr)
            // allocate output byte array
            o_code := mload(0x40)
            mstore(o_code, size) // store length in memory
            // actually retrieve the code
            extcodecopy(addr, add(o_code, 0x20), 0, size)
        }
        return keccak256(o_code);
    }
}

///File: ./contracts/PledgeAdmins.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
                  Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/



contract PledgeAdmins is AragonApp, LiquidPledgingPlugins {

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_SUBPROJECT_LEVEL = 20;
    uint constant MAX_INTERPROJECT_LEVEL = 20;

    // Events
    event GiverAdded(uint64 indexed idGiver, string url);
    event GiverUpdated(uint64 indexed idGiver, string url);
    event DelegateAdded(uint64 indexed idDelegate, string url);
    event DelegateUpdated(uint64 indexed idDelegate, string url);
    event ProjectAdded(uint64 indexed idProject, string url);
    event ProjectUpdated(uint64 indexed idProject, string url);

////////////////////
// Public functions
////////////////////

    /// @notice Creates a Giver Admin with the `msg.sender` as the Admin address
    /// @param name The name used to identify the Giver
    /// @param url The link to the Giver's profile often an IPFS hash
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param plugin This is Giver's liquid pledge plugin allowing for
    ///  extended functionality
    /// @return idGiver The id number used to reference this Admin
    function addGiver(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) external returns (uint64 idGiver)
    {
        return addGiver(
            msg.sender,
            name,
            url,
            commitTime,
            plugin
        );
    }

    function addGiver(
        address addr,
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) public returns (uint64 idGiver)
    {
        require(isValidPlugin(plugin)); // Plugin check

        idGiver = uint64(admins.length);

        // Save the fields
        admins.push(
            PledgeAdmin(
                PledgeAdminType.Giver,
                addr,
                commitTime,
                0,
                false,
                plugin,
                name,
                url)
        );

        GiverAdded(idGiver, url);
    }

    /// @notice Updates a Giver's info to change the address, name, url, or
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Giver
    /// @param idGiver This is the Admin id number used to specify the Giver
    /// @param newAddr The new address that represents this Giver
    /// @param newName The new name used to identify the Giver
    /// @param newUrl The new link to the Giver's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    function updateGiver(
        uint64 idGiver,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) external 
    {
        PledgeAdmin storage giver = _findAdmin(idGiver);
        require(msg.sender == giver.addr);
        require(giver.adminType == PledgeAdminType.Giver); // Must be a Giver
        giver.addr = newAddr;
        giver.name = newName;
        giver.url = newUrl;
        giver.commitTime = newCommitTime;

        GiverUpdated(idGiver, newUrl);
    }

    /// @notice Creates a Delegate Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Delegate
    /// @param url The link to the Delegate's profile often an IPFS hash
    /// @param commitTime Sets the length of time in seconds that this delegate
    ///  can be vetoed. Whenever this delegate is in a delegate chain the time
    ///  allowed to veto any event must be greater than or equal to this time.
    /// @param plugin This is Delegate's liquid pledge plugin allowing for
    ///  extended functionality
    /// @return idxDelegate The id number used to reference this Delegate within
    ///  the PLEDGE_ADMIN array
    function addDelegate(
        string name,
        string url,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) external returns (uint64 idDelegate) 
    {
        require(isValidPlugin(plugin)); // Plugin check

        idDelegate = uint64(admins.length);

        admins.push(
            PledgeAdmin(
                PledgeAdminType.Delegate,
                msg.sender,
                commitTime,
                0,
                false,
                plugin,
                name,
                url)
        );

        DelegateAdded(idDelegate, url);
    }

    /// @notice Updates a Delegate's info to change the address, name, url, or
    ///  commitTime, it cannot be used to change a plugin, and it must be called
    ///  by the current address of the Delegate
    /// @param idDelegate The Admin id number used to specify the Delegate
    /// @param newAddr The new address that represents this Delegate
    /// @param newName The new name used to identify the Delegate
    /// @param newUrl The new link to the Delegate's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds that this
    ///  delegate can be vetoed. Whenever this delegate is in a delegate chain
    ///  the time allowed to veto any event must be greater than or equal to
    ///  this time.
    function updateDelegate(
        uint64 idDelegate,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) external 
    {
        PledgeAdmin storage delegate = _findAdmin(idDelegate);
        require(msg.sender == delegate.addr);
        require(delegate.adminType == PledgeAdminType.Delegate);
        delegate.addr = newAddr;
        delegate.name = newName;
        delegate.url = newUrl;
        delegate.commitTime = newCommitTime;

        DelegateUpdated(idDelegate, newUrl);
    }

    /// @notice Creates a Project Admin with the `msg.sender` as the Admin addr
    /// @param name The name used to identify the Project
    /// @param url The link to the Project's profile often an IPFS hash
    /// @param projectAdmin The address for the trusted project manager
    /// @param parentProject The Admin id number for the parent project or 0 if
    ///  there is no parentProject
    /// @param commitTime Sets the length of time in seconds the Project has to
    ///   veto when the Project delegates to another Delegate and they pledge
    ///   those funds to a project
    /// @param plugin This is Project's liquid pledge plugin allowing for
    ///  extended functionality
    /// @return idProject The id number used to reference this Admin
    function addProject(
        string name,
        string url,
        address projectAdmin,
        uint64 parentProject,
        uint64 commitTime,
        ILiquidPledgingPlugin plugin
    ) external returns (uint64 idProject) 
    {
        require(isValidPlugin(plugin));

        if (parentProject != 0) {
            PledgeAdmin storage a = _findAdmin(parentProject);
            // getProjectLevel will check that parentProject has a `Project` adminType
            require(_getProjectLevel(a) < MAX_SUBPROJECT_LEVEL);
        }

        idProject = uint64(admins.length);

        admins.push(
            PledgeAdmin(
                PledgeAdminType.Project,
                projectAdmin,
                commitTime,
                parentProject,
                false,
                plugin,
                name,
                url)
        );

        ProjectAdded(idProject, url);
    }

    /// @notice Updates a Project's info to change the address, name, url, or
    ///  commitTime, it cannot be used to change a plugin or a parentProject,
    ///  and it must be called by the current address of the Project
    /// @param idProject The Admin id number used to specify the Project
    /// @param newAddr The new address that represents this Project
    /// @param newName The new name used to identify the Project
    /// @param newUrl The new link to the Project's profile often an IPFS hash
    /// @param newCommitTime Sets the length of time in seconds the Project has
    ///  to veto when the Project delegates to a Delegate and they pledge those
    ///  funds to a project
    function updateProject(
        uint64 idProject,
        address newAddr,
        string newName,
        string newUrl,
        uint64 newCommitTime
    ) external 
    {
        PledgeAdmin storage project = _findAdmin(idProject);

        require(msg.sender == project.addr);
        require(project.adminType == PledgeAdminType.Project);

        project.addr = newAddr;
        project.name = newName;
        project.url = newUrl;
        project.commitTime = newCommitTime;

        ProjectUpdated(idProject, newUrl);
    }

/////////////////////////////
// Public constant functions
/////////////////////////////

    /// @notice A constant getter used to check how many total Admins exist
    /// @return The total number of admins (Givers, Delegates and Projects) .
    function numberOfPledgeAdmins() external view returns(uint) {
        return admins.length - 1;
    }

    /// @notice A constant getter to check the details of a specified Admin
    /// @return addr Account or contract address for admin
    /// @return name Name of the pledgeAdmin
    /// @return url The link to the Project's profile often an IPFS hash
    /// @return commitTime The length of time in seconds the Admin has to veto
    ///   when the Admin delegates to a Delegate and that Delegate pledges those
    ///   funds to a project
    /// @return parentProject The Admin id number for the parent project or 0
    ///  if there is no parentProject
    /// @return canceled 0 for Delegates & Givers, true if a Project has been
    ///  canceled
    /// @return plugin This is Project's liquidPledging plugin allowing for
    ///  extended functionality
    function getPledgeAdmin(uint64 idAdmin) external view returns (
        PledgeAdminType adminType,
        address addr,
        string name,
        string url,
        uint64 commitTime,
        uint64 parentProject,
        bool canceled,
        address plugin
    ) {
        PledgeAdmin storage a = _findAdmin(idAdmin);
        adminType = a.adminType;
        addr = a.addr;
        name = a.name;
        url = a.url;
        commitTime = a.commitTime;
        parentProject = a.parentProject;
        canceled = a.canceled;
        plugin = address(a.plugin);
    }

    /// @notice A getter to find if a specified Project has been canceled
    /// @param projectId The Admin id number used to specify the Project
    /// @return True if the Project has been canceled
    function isProjectCanceled(uint64 projectId)
        public view returns (bool)
    {
        PledgeAdmin storage a = _findAdmin(projectId);

        if (a.adminType == PledgeAdminType.Giver) {
            return false;
        }

        assert(a.adminType == PledgeAdminType.Project);

        if (a.canceled) {
            return true;
        }
        if (a.parentProject == 0) {
            return false;
        }

        return isProjectCanceled(a.parentProject);
    }

///////////////////
// Internal methods
///////////////////

    /// @notice A getter to look up a Admin's details
    /// @param idAdmin The id for the Admin to lookup
    /// @return The PledgeAdmin struct for the specified Admin
    function _findAdmin(uint64 idAdmin) internal view returns (PledgeAdmin storage) {
        require(idAdmin < admins.length);
        return admins[idAdmin];
    }

    /// @notice Find the level of authority a specific Project has
    ///  using a recursive loop
    /// @param a The project admin being queried
    /// @return The level of authority a specific Project has
    function _getProjectLevel(PledgeAdmin a) internal view returns(uint64) {
        assert(a.adminType == PledgeAdminType.Project);

        if (a.parentProject == 0) {
            return(1);
        }

        PledgeAdmin storage parent = _findAdmin(a.parentProject);
        return _getProjectLevel(parent) + 1;
    }
}

///File: ./contracts/Pledges.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
                  Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/




contract Pledges is AragonApp, LiquidPledgingStorage {

    // Limits inserted to prevent large loops that could prevent canceling
    uint constant MAX_DELEGATES = 10;

    // a constant for when a delegate is requested that is not in the system
    uint64 constant  NOTFOUND = 0xFFFFFFFFFFFFFFFF;

/////////////////////////////
// Public constant functions
////////////////////////////

    /// @notice A constant getter that returns the total number of pledges
    /// @return The total number of Pledges in the system
    function numberOfPledges() external view returns (uint) {
        return pledges.length - 1;
    }

    /// @notice A getter that returns the details of the specified pledge
    /// @param idPledge the id number of the pledge being queried
    /// @return the amount, owner, the number of delegates (but not the actual
    ///  delegates, the intendedProject (if any), the current commit time and
    ///  the previous pledge this pledge was derived from
    function getPledge(uint64 idPledge) external view returns(
        uint amount,
        uint64 owner,
        uint64 nDelegates,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        address token,
        PledgeState pledgeState
    ) {
        Pledge memory p = _findPledge(idPledge);
        amount = p.amount;
        owner = p.owner;
        nDelegates = uint64(p.delegationChain.length);
        intendedProject = p.intendedProject;
        commitTime = p.commitTime;
        oldPledge = p.oldPledge;
        token = p.token;
        pledgeState = p.pledgeState;
    }


////////////////////
// Internal methods
////////////////////

    /// @notice This creates a Pledge with an initial amount of 0 if one is not
    ///  created already; otherwise it finds the pledge with the specified
    ///  attributes; all pledges technically exist, if the pledge hasn't been
    ///  created in this system yet it simply isn't in the hash array
    ///  hPledge2idx[] yet
    /// @param owner The owner of the pledge being looked up
    /// @param delegationChain The list of delegates in order of authority
    /// @param intendedProject The project this pledge will Fund after the
    ///  commitTime has passed
    /// @param commitTime The length of time in seconds the Giver has to
    ///   veto when the Giver's delegates Pledge funds to a project
    /// @param oldPledge This value is used to store the pledge the current
    ///  pledge was came from, and in the case a Project is canceled, the Pledge
    ///  will revert back to it's previous state
    /// @param state The pledge state: Pledged, Paying, or state
    /// @return The hPledge2idx index number
    function _findOrCreatePledge(
        uint64 owner,
        uint64[] delegationChain,
        uint64 intendedProject,
        uint64 commitTime,
        uint64 oldPledge,
        address token,
        PledgeState state
    ) internal returns (uint64)
    {
        bytes32 hPledge = keccak256(delegationChain, owner, intendedProject, commitTime, oldPledge, token, state);
        uint64 id = hPledge2idx[hPledge];
        if (id > 0) {
            return id;
        }

        id = uint64(pledges.length);
        hPledge2idx[hPledge] = id;
        pledges.push(
            Pledge(
                0,
                delegationChain,
                owner,
                intendedProject,
                commitTime,
                oldPledge,
                token,
                state
            )
        );
        return id;
    }

    /// @param idPledge the id of the pledge to load from storage
    /// @return The Pledge
    function _findPledge(uint64 idPledge) internal view returns(Pledge storage) {
        require(idPledge < pledges.length);
        return pledges[idPledge];
    }

    /// @notice A getter that searches the delegationChain for the level of
    ///  authority a specific delegate has within a Pledge
    /// @param p The Pledge that will be searched
    /// @param idDelegate The specified delegate that's searched for
    /// @return If the delegate chain contains the delegate with the
    ///  `admins` array index `idDelegate` this returns that delegates
    ///  corresponding index in the delegationChain. Otherwise it returns
    ///  the NOTFOUND constant
    function _getDelegateIdx(Pledge p, uint64 idDelegate) internal pure returns(uint64) {
        for (uint i = 0; i < p.delegationChain.length; i++) {
            if (p.delegationChain[i] == idDelegate) {
                return uint64(i);
            }
        }
        return NOTFOUND;
    }

    /// @notice A getter to find how many old "parent" pledges a specific Pledge
    ///  had using a self-referential loop
    /// @param p The Pledge being queried
    /// @return The number of old "parent" pledges a specific Pledge had
    function _getPledgeLevel(Pledge p) internal view returns(uint) {
        if (p.oldPledge == 0) {
            return 0;
        }
        Pledge storage oldP = _findPledge(p.oldPledge);
        return _getPledgeLevel(oldP) + 1; // a loop lookup
    }
}


///File: ./contracts/LiquidPledgingBase.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina
    Contributors: Adrià Massanet <adria@codecontext.io>, RJ Ewing, Griff
    Green, Arthur Lunn

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/






/// @dev `LiquidPledgingBase` is the base level contract used to carry out
///  liquidPledging's most basic functions, mostly handling and searching the
///  data structures
contract LiquidPledgingBase is AragonApp, LiquidPledgingStorage, PledgeAdmins, Pledges {

    event Transfer(uint indexed from, uint indexed to, uint amount);
    event CancelProject(uint indexed idProject);

/////////////
// Modifiers
/////////////

    /// @dev The `vault`is the only addresses that can call a function with this
    ///  modifier
    modifier onlyVault() {
        require(msg.sender == address(vault));
        _;
    }

///////////////
// Constructor
///////////////

    /// @param _vault The vault where the ETH backing the pledges is stored
    function initialize(address _vault) onlyInit public {
        require(_vault != 0x0);
        initialized();

        vault = ILPVault(_vault);

        admins.length = 1; // we reserve the 0 admin
        pledges.length = 1; // we reserve the 0 pledge
    }


/////////////////////////////
// Public constant functions
/////////////////////////////

    /// @notice Getter to find Delegate w/ the Pledge ID & the Delegate index
    /// @param idPledge The id number representing the pledge being queried
    /// @param idxDelegate The index number for the delegate in this Pledge 
    function getPledgeDelegate(uint64 idPledge, uint64 idxDelegate) external view returns(
        uint64 idDelegate,
        address addr,
        string name
    ) {
        Pledge storage p = _findPledge(idPledge);
        idDelegate = p.delegationChain[idxDelegate - 1];
        PledgeAdmin storage delegate = _findAdmin(idDelegate);
        addr = delegate.addr;
        name = delegate.name;
    }

///////////////////
// Public functions
///////////////////

    /// @notice Only affects pledges with the Pledged PledgeState for 2 things:
    ///   #1: Checks if the pledge should be committed. This means that
    ///       if the pledge has an intendedProject and it is past the
    ///       commitTime, it changes the owner to be the proposed project
    ///       (The UI will have to read the commit time and manually do what
    ///       this function does to the pledge for the end user
    ///       at the expiration of the commitTime)
    ///
    ///   #2: Checks to make sure that if there has been a cancellation in the
    ///       chain of projects, the pledge's owner has been changed
    ///       appropriately.
    ///
    /// This function can be called by anybody at anytime on any pledge.
    ///  In general it can be called to force the calls of the affected 
    ///  plugins, which also need to be predicted by the UI
    /// @param idPledge This is the id of the pledge that will be normalized
    /// @return The normalized Pledge!
    function normalizePledge(uint64 idPledge) public returns(uint64) {
        Pledge storage p = _findPledge(idPledge);

        // Check to make sure this pledge hasn't already been used 
        // or is in the process of being used
        if (p.pledgeState != PledgeState.Pledged) {
            return idPledge;
        }

        // First send to a project if it's proposed and committed
        if ((p.intendedProject > 0) && ( _getTime() > p.commitTime)) {
            uint64 oldPledge = _findOrCreatePledge(
                p.owner,
                p.delegationChain,
                0,
                0,
                p.oldPledge,
                p.token,
                PledgeState.Pledged
            );
            uint64 toPledge = _findOrCreatePledge(
                p.intendedProject,
                new uint64[](0),
                0,
                0,
                oldPledge,
                p.token,
                PledgeState.Pledged
            );
            _doTransfer(idPledge, toPledge, p.amount);
            idPledge = toPledge;
            p = _findPledge(idPledge);
        }

        toPledge = _getOldestPledgeNotCanceled(idPledge);
        if (toPledge != idPledge) {
            _doTransfer(idPledge, toPledge, p.amount);
        }

        return toPledge;
    }

////////////////////
// Internal methods
////////////////////

    /// @notice A check to see if the msg.sender is the owner or the
    ///  plugin contract for a specific Admin
    /// @param idAdmin The id of the admin being checked
    function _checkAdminOwner(uint64 idAdmin) internal view {
        PledgeAdmin storage a = _findAdmin(idAdmin);
        require(msg.sender == address(a.plugin) || msg.sender == a.addr);
    }

    function _transfer( 
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal
    {
        require(idReceiver > 0); // prevent burning value
        idPledge = normalizePledge(idPledge);

        Pledge storage p = _findPledge(idPledge);
        PledgeAdmin storage receiver = _findAdmin(idReceiver);

        require(p.pledgeState == PledgeState.Pledged);

        // If the sender is the owner of the Pledge
        if (p.owner == idSender) {

            if (receiver.adminType == PledgeAdminType.Giver) {
                _transferOwnershipToGiver(idPledge, amount, idReceiver);
                return;
            } else if (receiver.adminType == PledgeAdminType.Project) {
                _transferOwnershipToProject(idPledge, amount, idReceiver);
                return;
            } else if (receiver.adminType == PledgeAdminType.Delegate) {

                uint recieverDIdx = _getDelegateIdx(p, idReceiver);
                if (p.intendedProject > 0 && recieverDIdx != NOTFOUND) {
                    // if there is an intendedProject and the receiver is in the delegationChain,
                    // then we want to preserve the delegationChain as this is a veto of the
                    // intendedProject by the owner

                    if (recieverDIdx == p.delegationChain.length - 1) {
                        uint64 toPledge = _findOrCreatePledge(
                            p.owner,
                            p.delegationChain,
                            0,
                            0,
                            p.oldPledge,
                            p.token,
                            PledgeState.Pledged);
                        _doTransfer(idPledge, toPledge, amount);
                        return;
                    }

                    _undelegate(idPledge, amount, p.delegationChain.length - receiverDIdx - 1);
                    return;
                }
                // owner is not vetoing an intendedProject and is transferring the pledge to a delegate,
                // so we want to reset the delegationChain
                idPledge = _undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length
                );
                _appendDelegate(idPledge, amount, idReceiver);
                return;
            }

            // This should never be reached as the receiver.adminType
            // should always be either a Giver, Project, or Delegate
            assert(false);
        }

        // If the sender is a Delegate
        uint senderDIdx = _getDelegateIdx(p, idSender);
        if (senderDIdx != NOTFOUND) {

            // And the receiver is another Giver
            if (receiver.adminType == PledgeAdminType.Giver) {
                // Only transfer to the Giver who owns the pledge
                assert(p.owner == idReceiver);
                _undelegate(idPledge, amount, p.delegationChain.length);
                return;
            }

            // And the receiver is another Delegate
            if (receiver.adminType == PledgeAdminType.Delegate) {
                uint receiverDIdx = _getDelegateIdx(p, idReceiver);

                // And not in the delegationChain or part of the delegationChain
                // is after the sender, then all of the other delegates after 
                // the sender are removed and the receiver is appended at the 
                // end of the delegationChain
                if (receiverDIdx == NOTFOUND || receiverDIdx > senderDIdx) {
                    idPledge = _undelegate(
                        idPledge,
                        amount,
                        p.delegationChain.length - senderDIdx - 1
                    );
                    _appendDelegate(idPledge, amount, idReceiver);
                    return;
                }

                // And is already part of the delegate chain but is before the
                //  sender, then the sender and all of the other delegates after
                //  the RECEIVER are removed from the delegationChain
                _undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length - receiverDIdx - 1
                );
                return;
            }

            // And the receiver is a Project, all the delegates after the sender
            //  are removed and the amount is pre-committed to the project
            if (receiver.adminType == PledgeAdminType.Project) {
                idPledge = _undelegate(
                    idPledge,
                    amount,
                    p.delegationChain.length - senderDIdx - 1
                );
                _proposeAssignProject(idPledge, amount, idReceiver);
                return;
            }
        }
        assert(false);  // When the sender is not an owner or a delegate
    }

    /// @notice `transferOwnershipToProject` allows for the transfer of
    ///  ownership to the project, but it can also be called by a project
    ///  to un-delegate everyone by setting one's own id for the idReceiver
    /// @param idPledge the id of the pledge to be transfered.
    /// @param amount Quantity of value that's being transfered
    /// @param idReceiver The new owner of the project (or self to un-delegate)
    function _transferOwnershipToProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledge storage p = _findPledge(idPledge);

        // Ensure that the pledge is not already at max pledge depth
        // and the project has not been canceled
        require(_getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 oldPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Pledged
        );
        uint64 toPledge = _findOrCreatePledge(
            idReceiver,                     // Set the new owner
            new uint64[](0),                // clear the delegation chain
            0,
            0,
            oldPledge,
            p.token,
            PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }   


    /// @notice `transferOwnershipToGiver` allows for the transfer of
    ///  value back to the Giver, value is placed in a pledged state
    ///  without being attached to a project, delegation chain, or time line.
    /// @param idPledge the id of the pledge to be transferred.
    /// @param amount Quantity of value that's being transferred
    /// @param idReceiver The new owner of the pledge
    function _transferOwnershipToGiver(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledge storage p = _findPledge(idPledge);

        uint64 toPledge = _findOrCreatePledge(
            idReceiver,
            new uint64[](0),
            0,
            0,
            0,
            p.token,
            PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge the id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's being chained.
    /// @param idReceiver The delegate to be added at the end of the chain
    function _appendDelegate(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledge storage p = _findPledge(idPledge);

        require(p.delegationChain.length < MAX_DELEGATES);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length + 1
        );
        for (uint i = 0; i < p.delegationChain.length; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }

        // Make the last item in the array the idReceiver
        newDelegationChain[p.delegationChain.length] = idReceiver;

        uint64 toPledge = _findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `appendDelegate` allows for a delegate to be added onto the
    ///  end of the delegate chain for a given Pledge.
    /// @param idPledge the id of the pledge thats delegate chain will be modified.
    /// @param amount Quantity of value that's shifted from delegates.
    /// @param q Number (or depth) of delegates to remove
    /// @return toPledge The id for the pledge being adjusted or created
    function _undelegate(
        uint64 idPledge,
        uint amount,
        uint q
    ) internal returns (uint64 toPledge)
    {
        Pledge storage p = _findPledge(idPledge);
        uint64[] memory newDelegationChain = new uint64[](
            p.delegationChain.length - q
        );

        for (uint i = 0; i < p.delegationChain.length - q; i++) {
            newDelegationChain[i] = p.delegationChain[i];
        }
        toPledge = _findOrCreatePledge(
            p.owner,
            newDelegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `proposeAssignProject` proposes the assignment of a pledge
    ///  to a specific project.
    /// @dev This function should potentially be named more specifically.
    /// @param idPledge the id of the pledge that will be assigned.
    /// @param amount Quantity of value this pledge leader would be assigned.
    /// @param idReceiver The project this pledge will potentially 
    ///  be assigned to.
    function _proposeAssignProject(
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) internal 
    {
        Pledge storage p = _findPledge(idPledge);

        require(_getPledgeLevel(p) < MAX_INTERPROJECT_LEVEL);
        require(!isProjectCanceled(idReceiver));

        uint64 toPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            idReceiver,
            uint64(_getTime() + _maxCommitTime(p)),
            p.oldPledge,
            p.token,
            PledgeState.Pledged
        );
        _doTransfer(idPledge, toPledge, amount);
    }

    /// @notice `doTransfer` is designed to allow for pledge amounts to be 
    ///  shifted around internally.
    /// @param from This is the id of the pledge from which value will be transferred.
    /// @param to This is the id of the pledge that value will be transferred to.
    /// @param _amount The amount of value that will be transferred.
    function _doTransfer(uint64 from, uint64 to, uint _amount) internal {
        uint amount = _callPlugins(true, from, to, _amount);
        if (from == to) {
            return;
        }
        if (amount == 0) {
            return;
        }

        Pledge storage pFrom = _findPledge(from);
        Pledge storage pTo = _findPledge(to);

        require(pFrom.amount >= amount);
        pFrom.amount -= amount;
        pTo.amount += amount;
        require(pTo.amount >= amount);

        Transfer(from, to, amount);
        _callPlugins(false, from, to, amount);
    }

    /// @notice A getter to find the longest commitTime out of the owner and all
    ///  the delegates for a specified pledge
    /// @param p The Pledge being queried
    /// @return The maximum commitTime out of the owner and all the delegates
    function _maxCommitTime(Pledge p) internal view returns(uint64 commitTime) {
        PledgeAdmin storage a = _findAdmin(p.owner);
        commitTime = a.commitTime; // start with the owner's commitTime

        for (uint i = 0; i < p.delegationChain.length; i++) {
            a = _findAdmin(p.delegationChain[i]);

            // If a delegate's commitTime is longer, make it the new commitTime
            if (a.commitTime > commitTime) {
                commitTime = a.commitTime;
            }
        }
    }

    /// @notice A getter to find the oldest pledge that hasn't been canceled
    /// @param idPledge The starting place to lookup the pledges
    /// @return The oldest idPledge that hasn't been canceled (DUH!)
    function _getOldestPledgeNotCanceled(
        uint64 idPledge
    ) internal view returns(uint64)
    {
        if (idPledge == 0) {
            return 0;
        }

        Pledge storage p = _findPledge(idPledge);
        PledgeAdmin storage admin = _findAdmin(p.owner);
        
        if (admin.adminType == PledgeAdminType.Giver) {
            return idPledge;
        }

        assert(admin.adminType == PledgeAdminType.Project);
        if (!isProjectCanceled(p.owner)) {
            return idPledge;
        }

        return _getOldestPledgeNotCanceled(p.oldPledge);
    }

    /// @notice `callPlugin` is used to trigger the general functions in the
    ///  plugin for any actions needed before and after a transfer happens.
    ///  Specifically what this does in relation to the plugin is something
    ///  that largely depends on the functions of that plugin. This function
    ///  is generally called in pairs, once before, and once after a transfer.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param adminId This should be the Id of the *trusted* individual
    ///  who has control over this plugin.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param context The situation that is triggering the plugin. See plugin
    ///  for a full description of contexts.
    /// @param amount The amount of value that is being transfered.
    function _callPlugin(
        bool before,
        uint64 adminId,
        uint64 fromPledge,
        uint64 toPledge,
        uint64 context,
        address token,
        uint amount
    ) internal returns (uint allowedAmount) 
    {
        uint newAmount;
        allowedAmount = amount;
        PledgeAdmin storage admin = _findAdmin(adminId);

        // Checks admin has a plugin assigned and a non-zero amount is requested
        if (address(admin.plugin) != 0 && allowedAmount > 0) {
            // There are two separate functions called in the plugin.
            // One is called before the transfer and one after
            if (before) {
                newAmount = admin.plugin.beforeTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    token,
                    amount
                );
                require(newAmount <= allowedAmount);
                allowedAmount = newAmount;
            } else {
                admin.plugin.afterTransfer(
                    adminId,
                    fromPledge,
                    toPledge,
                    context,
                    token,
                    amount
                );
            }
        }
    }

    /// @notice `callPluginsPledge` is used to apply plugin calls to
    ///  the delegate chain and the intended project if there is one.
    ///  It does so in either a transferring or receiving context based
    ///  on the `p` and  `fromPledge` parameters.
    /// @param before This toggle determines whether the plugin call is occuring
    ///  before or after a transfer.
    /// @param idPledge This is the id of the pledge on which this plugin
    ///  is being called.
    /// @param fromPledge This is the Id from which value is being transfered.
    /// @param toPledge This is the Id that value is being transfered to.
    /// @param amount The amount of value that is being transfered.
    function _callPluginsPledge(
        bool before,
        uint64 idPledge,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) 
    {
        // Determine if callPlugin is being applied in a receiving
        // or transferring context
        uint64 offset = idPledge == fromPledge ? 0 : 256;
        allowedAmount = amount;
        Pledge storage p = _findPledge(idPledge);

        // Always call the plugin on the owner
        allowedAmount = _callPlugin(
            before,
            p.owner,
            fromPledge,
            toPledge,
            offset,
            p.token,
            allowedAmount
        );

        // Apply call plugin to all delegates
        for (uint64 i = 0; i < p.delegationChain.length; i++) {
            allowedAmount = _callPlugin(
                before,
                p.delegationChain[i],
                fromPledge,
                toPledge,
                offset + i + 1,
                p.token,
                allowedAmount
            );
        }

        // If there is an intended project also call the plugin in
        // either a transferring or receiving context based on offset
        // on the intended project
        if (p.intendedProject > 0) {
            allowedAmount = _callPlugin(
                before,
                p.intendedProject,
                fromPledge,
                toPledge,
                offset + 255,
                p.token,
                allowedAmount
            );
        }
    }

    /// @notice `callPlugins` calls `callPluginsPledge` once for the transfer
    ///  context and once for the receiving context. The aggregated 
    ///  allowed amount is then returned.
    /// @param before This toggle determines whether the plugin call is occurring
    ///  before or after a transfer.
    /// @param fromPledge This is the Id from which value is being transferred.
    /// @param toPledge This is the Id that value is being transferred to.
    /// @param amount The amount of value that is being transferred.
    function _callPlugins(
        bool before,
        uint64 fromPledge,
        uint64 toPledge,
        uint amount
    ) internal returns (uint allowedAmount) 
    {
        allowedAmount = amount;

        // Call the plugins in the transfer context
        allowedAmount = _callPluginsPledge(
            before,
            fromPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );

        // Call the plugins in the receive context
        allowedAmount = _callPluginsPledge(
            before,
            toPledge,
            fromPledge,
            toPledge,
            allowedAmount
        );
    }

/////////////
// Test functions
/////////////

    /// @notice Basic helper function to return the current time
    function _getTime() internal view returns (uint) {
        return now;
    }
}


///File: ./contracts/LiquidPledging.sol

pragma solidity ^0.4.18;

/*
    Copyright 2017, Jordi Baylina, RJ Ewing
    Contributors: Adrià Massanet <adria@codecontext.io>, Griff Green,
    Arthur Lunn, Satya van Heummen <satya.vh@gmail.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/



/// @dev `LiquidPledging` allows for liquid pledging through the use of
///  internal id structures and delegate chaining. All basic operations for
///  handling liquid pledging are supplied as well as plugin features
///  to allow for expanded functionality.
contract LiquidPledging is LiquidPledgingBase {

    /// @notice Make a donation in Ether, basically forwarding to addGiverAndDonate method,
    ///  setting msg.sender as the "giver" of this donation
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project    
    function addGiverAndDonate(uint64 idReceiver)
        public
        payable
    {
        addGiverAndDonate(idReceiver, msg.sender, ETH, msg.value);
    }

    /// @notice Make a donation in Ether on behalf of another Giver
    ///  basically forwarding to addGiverAndDonate method
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    /// @param donorAddress The address of the "giver" of this donation    
    function addGiverAndDonate(uint64 idReceiver, address donorAddress)
        public
        payable
    {
        addGiverAndDonate(idReceiver, donorAddress, ETH, msg.value);
    }    

    /// Create a "giver" pledge admin for the sender & donate 
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    /// @param token The address of the token being donated.
    /// @param amount The amount of tokens being donated
    function addGiverAndDonate(uint64 idReceiver, address token, uint amount)
        public
    {
        addGiverAndDonate(idReceiver, msg.sender, token, amount);
    }

    /// Create a "giver" pledge admin for the given `donorAddress` & donate 
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    /// @param donorAddress The address of the "giver" of this donation
    /// @param token The address of the token being donated.
    /// @param amount The amount of tokens being donated
    function addGiverAndDonate(uint64 idReceiver, address donorAddress, address token, uint amount)
        public
    {
        require(donorAddress != 0);
        // default to a 3 day (259200 seconds) commitTime
        uint64 idGiver = addGiver(donorAddress, "", "", 259200, ILiquidPledgingPlugin(0));
        donate(idGiver, idReceiver, token, amount);
    }

    /// @notice Make a donation in Ether, basically forwarding to donate method
    ///  setting the msg.sender as the "giver" of the donation
    /// @param idGiver The id of the Giver donating
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    function donate(uint64 idGiver, uint64 idReceiver)
        public
        payable
    {
        donate(idGiver, idReceiver, ETH, msg.value);
    }

    /// @notice This is how value enters the system and how pledges are created;
    ///  the ether is sent to the vault, a pledge for the Giver is created (or
    ///  found), the amount of ETH donated in wei is added to the `amount` in
    ///  the Giver's Pledge, and an LP transfer is done to the idReceiver for
    ///  the full amount
    /// @param idGiver The id of the Giver donating
    /// @param idReceiver The Admin receiving the donation; can be any Admin:
    ///  the Giver themselves, another Giver, a Delegate or a Project
    /// @param token The address of the token being donated.
    /// @param amount The amount of tokens being donated
    function donate(uint64 idGiver, uint64 idReceiver, address token, uint amount)
        public
    {
        require(idGiver > 0); // prevent burning donations. idReceiver is checked in _transfer
        require(amount > 0);

        PledgeAdmin storage sender = _findAdmin(idGiver);
        require(sender.adminType == PledgeAdminType.Giver);

        // transfer ether or token to the `vault`
        if (token == ETH) {
            vault.transfer(amount);
        } else {
            require(ERC20(token).transferFrom(msg.sender, address(vault), amount));
        }

        uint64 idPledge = _findOrCreatePledge(
            idGiver,
            new uint64[](0), // Creates empty array for delegationChain
            0,
            0,
            0,
            token,
            PledgeState.Pledged
        );

        Pledge storage pTo = _findPledge(idPledge);
        pTo.amount += amount;

        Transfer(0, idPledge, amount);

        _transfer(idGiver, idPledge, amount, idReceiver);
    }

    /// @notice Transfers amounts between pledges for internal accounting
    /// @param idSender Id of the Admin that is transferring the amount from
    ///  Pledge to Pledge; this admin must have permissions to move the value
    /// @param idPledge Id of the pledge that's moving the value
    /// @param amount Quantity of ETH (in wei) that this pledge is transferring 
    ///  the authority to withdraw from the vault
    /// @param idReceiver Destination of the `amount`, can be a Giver/Project sending
    ///  to a Giver, a Delegate or a Project; a Delegate sending to another
    ///  Delegate, or a Delegate pre-commiting it to a Project 
    function transfer( 
        uint64 idSender,
        uint64 idPledge,
        uint amount,
        uint64 idReceiver
    ) public
    {
        _checkAdminOwner(idSender);
        _transfer(idSender, idPledge, amount, idReceiver);
    }

    /// @notice Authorizes a payment be made from the `vault` can be used by the
    ///  Giver to veto a pre-committed donation from a Delegate to an
    ///  intendedProject
    /// @param idPledge Id of the pledge that is to be redeemed into ether
    /// @param amount Quantity of ether (in wei) to be authorized
    function withdraw(uint64 idPledge, uint amount) public {
        idPledge = normalizePledge(idPledge); // Updates pledge info 

        Pledge storage p = _findPledge(idPledge);
        require(p.pledgeState == PledgeState.Pledged);
        _checkAdminOwner(p.owner);

        uint64 idNewPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Paying
        );

        _doTransfer(idPledge, idNewPledge, amount);

        PledgeAdmin storage owner = _findAdmin(p.owner);
        vault.authorizePayment(bytes32(idNewPledge), owner.addr, p.token, amount);
    }

    /// @notice `onlyVault` Confirms a withdraw request changing the PledgeState
    ///  from Paying to Paid
    /// @param idPledge Id of the pledge that is to be withdrawn
    /// @param amount Quantity of ether (in wei) to be withdrawn
    function confirmPayment(uint64 idPledge, uint amount) public onlyVault {
        Pledge storage p = _findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying);

        uint64 idNewPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Paid
        );

        _doTransfer(idPledge, idNewPledge, amount);
    }

    /// @notice `onlyVault` Cancels a withdraw request, changing the PledgeState
    ///  from Paying back to Pledged
    /// @param idPledge Id of the pledge that's withdraw is to be canceled
    /// @param amount Quantity of ether (in wei) to be canceled
    function cancelPayment(uint64 idPledge, uint amount) public onlyVault {
        Pledge storage p = _findPledge(idPledge);

        require(p.pledgeState == PledgeState.Paying);

        // When a payment is canceled, never is assigned to a project.
        uint64 idOldPledge = _findOrCreatePledge(
            p.owner,
            p.delegationChain,
            0,
            0,
            p.oldPledge,
            p.token,
            PledgeState.Pledged
        );

        idOldPledge = normalizePledge(idOldPledge);

        _doTransfer(idPledge, idOldPledge, amount);
    }

    /// @notice Changes the `project.canceled` flag to `true`; cannot be undone
    /// @param idProject Id of the project that is to be canceled
    function cancelProject(uint64 idProject) public {
        PledgeAdmin storage project = _findAdmin(idProject);
        _checkAdminOwner(idProject);
        project.canceled = true;

        CancelProject(idProject);
    }

    /// @notice Transfers `amount` in `idPledge` back to the `oldPledge` that
    ///  that sent it there in the first place, a Ctrl-z 
    /// @param idPledge Id of the pledge that is to be canceled
    /// @param amount Quantity of ether (in wei) to be transfered to the 
    ///  `oldPledge`
    function cancelPledge(uint64 idPledge, uint amount) public {
        idPledge = normalizePledge(idPledge);

        Pledge storage p = _findPledge(idPledge);
        require(p.oldPledge != 0);
        require(p.pledgeState == PledgeState.Pledged);
        _checkAdminOwner(p.owner);

        uint64 oldPledge = _getOldestPledgeNotCanceled(p.oldPledge);
        _doTransfer(idPledge, oldPledge, amount);
    }


////////
// Multi pledge methods
////////

    // @dev This set of functions makes moving a lot of pledges around much more
    // efficient (saves gas) than calling these functions in series
    
    
    /// @dev Bitmask used for dividing pledge amounts in Multi pledge methods
    uint constant D64 = 0x10000000000000000;

    /// @notice Transfers multiple amounts within multiple Pledges in an
    ///  efficient single call 
    /// @param idSender Id of the Admin that is transferring the amounts from
    ///  all the Pledges; this admin must have permissions to move the value
    /// @param pledgesAmounts An array of Pledge amounts and the idPledges with 
    ///  which the amounts are associated; these are extrapolated using the D64
    ///  bitmask
    /// @param idReceiver Destination of the `pledesAmounts`, can be a Giver or 
    ///  Project sending to a Giver, a Delegate or a Project; a Delegate sending
    ///  to another Delegate, or a Delegate pre-commiting it to a Project 
    function mTransfer(
        uint64 idSender,
        uint[] pledgesAmounts,
        uint64 idReceiver
    ) public 
    {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64(pledgesAmounts[i] & (D64-1));
            uint amount = pledgesAmounts[i] / D64;

            transfer(idSender, idPledge, amount, idReceiver);
        }
    }

    /// @notice Authorizes multiple amounts within multiple Pledges to be
    ///  withdrawn from the `vault` in an efficient single call 
    /// @param pledgesAmounts An array of Pledge amounts and the idPledges with 
    ///  which the amounts are associated; these are extrapolated using the D64
    ///  bitmask
    function mWithdraw(uint[] pledgesAmounts) public {
        for (uint i = 0; i < pledgesAmounts.length; i++ ) {
            uint64 idPledge = uint64(pledgesAmounts[i] & (D64-1));
            uint amount = pledgesAmounts[i] / D64;

            withdraw(idPledge, amount);
        }
    }

    /// @notice `mNormalizePledge` allows for multiple pledges to be
    ///  normalized efficiently
    /// @param pledges An array of pledge IDs
    function mNormalizePledge(uint64[] pledges) public {
        for (uint i = 0; i < pledges.length; i++ ) {
            normalizePledge(pledges[i]);
        }
    }
}


///File: ./contracts/LPConstants.sol

pragma solidity ^0.4.18;



contract LPConstants is KernelConstants {
    bytes32 constant public VAULT_APP_ID = keccak256("vault");
    bytes32 constant public LP_APP_ID = keccak256("liquidPledging");
}

///File: ./contracts/LPFactory.sol

pragma solidity ^0.4.18;






contract LPFactory is LPConstants, DAOFactory(new Kernel(), new ACL(), 0) {
    bytes32 public constant RECOVERY_VAULT_ID = keccak256("recoveryVault");
    address public vaultBase;
    address public lpBase;

    event DeployVault(address vault);
    event DeployLiquidPledging(address liquidPledging);

    function LPFactory(address _vaultBase, address _lpBase) public {
        require(_vaultBase != 0);
        require(_lpBase != 0);
        vaultBase = _vaultBase;
        lpBase = _lpBase;
    }

    function newLP(address _root, address _escapeHatchDestination) external {
        Kernel kernel = newDAO(this);
        ACL acl = ACL(kernel.acl());

        bytes32 appManagerRole = kernel.APP_MANAGER_ROLE();

        acl.createPermission(this, address(kernel), appManagerRole, this);

        LPVault v = LPVault(kernel.newAppInstance(VAULT_APP_ID, vaultBase));
        // deploy & register the lp instance w/ the kernel
        LiquidPledging lp = LiquidPledging(kernel.newAppInstance(LP_APP_ID, lpBase, true));
        v.initialize(address(lp));
        lp.initialize(address(v));

        // set the recoveryVault to the escapeHatchDestination
        kernel.setRecoveryVaultId(RECOVERY_VAULT_ID);
        kernel.setApp(APP_ADDR_NAMESPACE, RECOVERY_VAULT_ID, _escapeHatchDestination);

        _setPermissions(_root, acl, kernel, v, lp);
    }

    function _setPermissions(address _root, ACL acl, Kernel kernel, LPVault v, LiquidPledging lp) internal {
        bytes32 appManagerRole = kernel.APP_MANAGER_ROLE();
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

        DeployVault(address(v));
        DeployLiquidPledging(address(lp));
    }
}