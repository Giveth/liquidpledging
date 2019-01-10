

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


///File: @aragon/os/contracts/common/EtherTokenConstant.sol

pragma solidity ^0.4.18;


// aragonOS and aragon-apps rely on address(0) to denote native ETH, in
// contracts where both tokens and ETH are accepted
contract EtherTokenConstant {
    address constant public ETH = address(0);
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
