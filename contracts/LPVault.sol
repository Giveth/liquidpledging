pragma solidity ^0.4.11;

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

/// @title LPVault
/// @author Jordi Baylina

/// @dev This contract holds ether securely for liquid pledging systems; for
///  this iteration the funds will come often be escaped to the Giveth Multisig
///  (safety precaution), but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escapeHatch to be implemented in case of issues;
///  future versions of this contract will be enabled for tokens
import "giveth-common-contracts/contracts/Escapable.sol";

/// @dev `LiquidPledging` is a basic interface to allow the `LPVault` contract
///  to confirm and cancel payments in the `LiquidPledging` contract.
contract LiquidPledging {
    function confirmPayment(uint64 idPledge, uint amount) public;
    function cancelPayment(uint64 idPledge, uint amount) public;
}


/// @dev `LPVault` is a higher level contract built off of the `Escapable`
///  contract that holds funds for the liquid pledging system.
contract LPVault is Escapable {

    LiquidPledging public liquidPledging; // LiquidPledging contract's address
    bool public autoPay; // If false, payments will take 2 txs to be completed

    enum PaymentStatus {
        Pending, // When the payment is awaiting confirmation
        Paid,    // When the payment has been sent
        Canceled // When the payment will never be sent
    }
    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment the `ref` param makes it easy to track the movements of
    ///  funds transparently by its connection to other `Payment` structs
    struct Payment {
        PaymentStatus state; // Pending, Paid or Canceled
        bytes32 ref; // an input that references details from other contracts
        address dest; // recipient of the ETH
        uint amount; // amount of ETH (in wei) to be sent
    }

    // @dev An array that contains all the payments for this LPVault
    Payment[] public payments;

    function LPVault(address _escapeHatchCaller, address _escapeHatchDestination)
        Escapable(_escapeHatchCaller, _escapeHatchDestination) public
    {
    }

    /// @dev The attached `LiquidPledging` contract is the only address that can
    ///  call a function with this modifier
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }

    /// @dev The fall back function allows ETH to be deposited into the LPVault
    ///  through a simple send
    function () public payable {}

    /// @notice `onlyOwner` used to attach a specific liquidPledging instance
    ///  to this LPvault; keep in mind that once a liquidPledging contract is 
    ///  attached it cannot be undone, this vault will be forever connected
    /// @param _newLiquidPledging A full liquid pledging contract
    function setLiquidPledging(address _newLiquidPledging) public onlyOwner {
        require(address(liquidPledging) == 0x0);
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

    /// @notice Used to decentralize, toggles whether the LPVault will
    ///  automatically confirm a payment after the payment has been authorized
    /// @param _automatic If true, payments will confirm instantly, if false
    ///  the training wheels are put on and the owner must manually approve 
    ///  every payment
    function setAutopay(bool _automatic) public onlyOwner {
        autoPay = _automatic;
        AutoPaySet();
    }

    /// @notice `onlyLiquidPledging` authorizes payments from this contract, if 
    ///  `autoPay == true` the transfer happens automatically `else` the `owner`
    ///  must call `confirmPayment()` for a transfer to occur (training wheels);
    ///  either way, a new payment is added to `payments[]` 
    /// @param _ref References the payment will normally be the pledgeID
    /// @param _dest The address that payments will be sent to
    /// @param _amount The amount that the payment is being authorized for
    /// @return idPayment The id of the payment (needed by the owner to confirm)
    function authorizePayment(
        bytes32 _ref,
        address _dest,
        uint _amount
    ) public onlyLiquidPledging returns (uint)
    {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentStatus.Pending;
        payments[idPayment].ref = _ref;
        payments[idPayment].dest = _dest;
        payments[idPayment].amount = _amount;

        AuthorizePayment(idPayment, _ref, _dest, _amount);

        if (autoPay) {
            doConfirmPayment(idPayment);
        }

        return idPayment;
    }

    /// @notice Allows the owner to confirm payments;  since 
    ///  `authorizePayment` is the only way to populate the `payments[]` array
    ///  this is generally used when `autopay` is `false` after a payment has
    ///  has been authorized
    /// @param _idPayment Array lookup for the payment.
    function confirmPayment(uint _idPayment) public onlyOwner {
        doConfirmPayment(_idPayment);
    }

    /// @notice Transfers ETH according to the data held within the specified
    ///  payment id (internal function)
    /// @param _idPayment id number for the payment about to be fulfilled 
    function doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        p.dest.transfer(p.amount);  // Transfers ETH denominated in wei

        ConfirmPayment(_idPayment);
    }

    /// @notice When `autopay` is `false` and after a payment has been authorized
    ///  to allow the owner to cancel a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.
    function cancelPayment(uint _idPayment) public onlyOwner {
        doCancelPayment(_idPayment);
    }

    /// @notice Cancels a pending payment (internal function)
    /// @param _idPayment id number for the payment    
    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment);

    }

    /// @notice `onlyOwner` An efficient way to confirm multiple payments
    /// @param _idPayments An array of multiple payment ids
    function multiConfirm(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doConfirmPayment(_idPayments[i]);
        }
    }

    /// @notice `onlyOwner` An efficient way to cancel multiple payments
    /// @param _idPayments An array of multiple payment ids
    function multiCancel(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doCancelPayment(_idPayments[i]);
        }
    }

    /// @return The total number of payments that have ever been authorized
    function nPayments() constant public returns (uint) {
        return payments.length;
    }

    /// Transfer eth or tokens to the escapeHatchDestination.
    /// Used as a safety mechanism to prevent the vault from holding too much value
    /// before being thoroughly battle-tested.
    /// @param _token to transfer, use 0x0 for ether
    /// @param _amount to transfer
    function escapeFunds(address _token, uint _amount) public onlyOwner {
        /// @dev Logic for ether
        if (_token == 0x0) {
            require(this.balance >= _amount);
            escapeHatchDestination.transfer(_amount);
            EscapeHatchCalled(_token, _amount);
            return;
        }
        /// @dev Logic for tokens
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        require(balance >= _amount);
        require(token.transfer(escapeHatchDestination, _amount));
        EscapeFundsCalled(_token, _amount);
    }

    event AutoPaySet();
    event EscapeFundsCalled(address token, uint amount);
    event ConfirmPayment(uint indexed idPayment);
    event CancelPayment(uint indexed idPayment);
    event AuthorizePayment(
        uint indexed idPayment,
        bytes32 indexed ref,
        address indexed dest,
        uint amount
        );
}
