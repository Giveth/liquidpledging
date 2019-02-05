pragma solidity ^0.4.24;

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
import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/common/DepositableStorage.sol";
import "./ILiquidPledging.sol";
import "./ILPVault.sol";


/// @dev `LPVault` is a higher level contract built off of the `Escapable`
///  contract that holds funds for the liquid pledging system.
contract LPVault is ILPVault, AragonApp, DepositableStorage {

    // bytes32 constant public _CONFIRM_PAYMENT_ROLE = keccak256("CONFIRM_PAYMENT_ROLE");
    bytes32 constant public _CONFIRM_PAYMENT_ROLE = 0xe8d376fd78e6f5f651a4bd073ee95d38284b2e197d7a9e6aad3a164cdbd7153f;
    // bytes32 constant public _CANCEL_PAYMENT_ROLE = keccak256("CANCEL_PAYMENT_ROLE");
    bytes32 constant public _CANCEL_PAYMENT_ROLE = 0xe4de6c9a7465378b041e537fffee313ab2189e2b84c50d3c50009e36c08411db;
    // bytes32 constant public _SET_AUTOPAY_ROLE = keccak256("SET_AUTOPAY_ROLE");
    bytes32 constant public _SET_AUTOPAY_ROLE = 0xbde66017e8446645910062da94d2713ea718e2ed728af167a4286b7fb283e30e;
    // bytes32 constant public _ESCAPE_HATCH_CALLER_ROLE = keccak256("ESCAPE_HATCH_CALLER_ROLE");
    bytes32 constant public _ESCAPE_HATCH_CALLER_ROLE = 0x5cfc63e96cb331fc218d6862d4ebcdb7abc1c4800aecb569045bebab5aa4a47a;

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
        setDepositable(true);

        liquidPledging = ILiquidPledging(_liquidPledging);
    }

    /// @notice Used to decentralize, toggles whether the LPVault will
    ///  automatically confirm a payment after the payment has been authorized
    /// @param _automatic If true, payments will confirm instantly, if false
    ///  the training wheels are put on and the owner must manually approve 
    ///  every payment
    function setAutopay(bool _automatic) external auth(_SET_AUTOPAY_ROLE) {
        autoPay = _automatic;
        emit AutoPaySet(autoPay);
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

        emit AuthorizePayment(idPayment, _ref, _dest, _token, _amount);

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
        require(canPerform(msg.sender, _CONFIRM_PAYMENT_ROLE, arr(_idPayment, p.amount)));
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
        return canPerform(msg.sender, _ESCAPE_HATCH_CALLER_ROLE, arr(token));
    }

    /// @return The total number of payments that have ever been authorized
    function nPayments() external view returns (uint) {
        return payments.length;
    }

    // we provide a pure function here to satisfy the ILPVault interface
    // the compiler will generate this function for public constant variables, but will not 
    // recognize that the interface has been satisfied and thus will not generate the bytecode
    function CONFIRM_PAYMENT_ROLE() external pure returns (bytes32) { return _CONFIRM_PAYMENT_ROLE; }
    function CANCEL_PAYMENT_ROLE() external pure returns (bytes32) { return _CANCEL_PAYMENT_ROLE; }
    function SET_AUTOPAY_ROLE() external pure returns (bytes32) { return _SET_AUTOPAY_ROLE; }
    function ESCAPE_HATCH_CALLER_ROLE() external pure returns (bytes32) { return _ESCAPE_HATCH_CALLER_ROLE; }


    /// @dev The fall back function allows ETH to be deposited into the LPVault
    ///  through a simple send
    function() external payable {}    

    /// @notice Transfers ETH according to the data held within the specified
    ///  payment id (internal function)
    /// @param _idPayment id number for the payment about to be fulfilled 
    function _doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        if (p.token == ETH) {
            p.dest.transfer(p.amount);
        } else {
            ERC20 token = ERC20(p.token);
            require(token.transfer(p.dest, p.amount)); // Transfers token to dest
        }

        emit ConfirmPayment(_idPayment, p.ref);
    }

    /// @notice Cancels a pending payment (internal function)
    /// @param _idPayment id number for the payment    
    function _doCancelPayment(uint _idPayment) internal authP(_CANCEL_PAYMENT_ROLE, arr(_idPayment)) {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        emit CancelPayment(_idPayment, p.ref);
    }
}
