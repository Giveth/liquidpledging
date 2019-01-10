

///File: ./node_modules/@aragon/os/contracts/acl/IACL.sol

pragma solidity ^0.4.18;


interface IACL {
    function initialize(address permissionsCreator) public;
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}


///File: ./node_modules/@aragon/os/contracts/common/IVaultRecoverable.sol

pragma solidity ^0.4.18;


interface IVaultRecoverable {
    function transferToVault(address token) external;

    function allowRecoverability(address token) public view returns (bool);
    function getRecoveryVault() public view returns (address);
}


///File: ./node_modules/@aragon/os/contracts/kernel/IKernel.sol

pragma solidity ^0.4.18;





// This should be an interface, but interfaces can't inherit yet :(
contract IKernel is IVaultRecoverable {
    event SetApp(bytes32 indexed namespace, bytes32 indexed name, bytes32 indexed id, address app);

    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 name, address app) public returns (bytes32 id);
    function getApp(bytes32 id) public view returns (address);
}


///File: ./node_modules/@aragon/os/contracts/apps/AppStorage.sol

pragma solidity ^0.4.18;




contract AppStorage {
    IKernel public kernel;
    bytes32 public appId;
    address internal pinnedCode; // used by Proxy Pinned
    uint256 internal initializationBlock; // used by Initializable
    uint256[95] private storageOffset; // forces App storage to start at after 100 slots
    uint256 private offset;
}


///File: ./node_modules/@aragon/os/contracts/common/IsContract.sol

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


///File: ./node_modules/@aragon/os/contracts/lib/misc/ERCProxy.sol

pragma solidity ^0.4.18;


contract ERCProxy {
    uint256 constant public FORWARDING = 1;
    uint256 constant public UPGRADEABLE = 2;

    function proxyType() public pure returns (uint256 proxyTypeId);
    function implementation() public view returns (address codeAddr);
}


///File: ./node_modules/@aragon/os/contracts/common/DelegateProxy.sol

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


///File: ./node_modules/@aragon/os/contracts/common/DepositableDelegateProxy.sol

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


///File: ./node_modules/@aragon/os/contracts/kernel/KernelStorage.sol

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


///File: ./node_modules/@aragon/os/contracts/apps/AppProxyBase.sol

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


///File: ./node_modules/@aragon/os/contracts/apps/AppProxyUpgradeable.sol

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
