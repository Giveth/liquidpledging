pragma solidity ^0.4.11;

/// @title Vault
/// @author Jordi Baylina
/// @notice This contract holds ether securely for liquid pledging systems. For
///  this iteration the funds will come straight from the Giveth Multisig as a
///  safety precaution, but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escape hatch to be implemented
import "../node_modules/giveth-common-contracts/contracts/Owned.sol";

/// @dev This is declares a few functions from `LiquidPledging` so that the
///  `Vault` contract can interface with the `LiquidPledging` contract
contract LiquidPledging {
    function confirmPayment(uint64 idNote, uint amount);
    function cancelPayment(uint64 idNote, uint amount);
}


/// @dev `Vault` is a higher level contract built off of the `Owned`
///  contract that holds funds for the liquid pledging system.
contract Vault is Owned {

    LiquidPledging public liquidPledging; // liquidPledging contract's address
    bool public autoPay; // if false, payments will take 2 txs to be completed

    enum PaymentStatus {
        Pending, // means the payment is awaiting confirmation
        Paid,    // means the payment has been sent
        Canceled // means the payment will never be sent
    }
    /// @dev `Payment` is a public structure that describes the details of
    ///  each payment the `ref` param makes it easy to track the movements of
    ///  funds transparently by its connection to other `Payment` structs
    struct Payment {
        PaymentStatus state; //
        bytes32 ref; // an input that references details from other contracts
        address dest; // recipient of the ETH
        uint amount; // amount of ETH (in wei) to be sent
    }

    // @dev An array that contains all the payments for this Vault
    Payment[] public payments;

    // @dev `liquidPledging` is the only address that can call a function with
    /// this modifier
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }
    /// @dev USED FOR TESTING???
    function VaultMock() {

    }

    function () payable {

    }

    function setLiquidPledging(address _newLiquidPledging) onlyOwner {
        require(address(liquidPledging) == 0x0);
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

    function setAutopay(bool _automatic) onlyOwner {
        autoPay = _automatic;
    }


    function authorizePayment(bytes32 _ref, address _dest, uint _amount) onlyLiquidPledging returns (uint) {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentStatus.Pending;
        payments[idPayment].ref = _ref;
        payments[idPayment].dest = _dest;
        payments[idPayment].amount = _amount;

        AuthorizePayment(idPayment, _ref, _dest,  _amount);

        if (autoPay) doConfirmPayment(idPayment);

        return idPayment;
    }

    function confirmPayment(uint _idPayment) onlyOwner {
        doConfirmPayment(_idPayment);
    }

    function doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        p.dest.transfer(p.amount);  // only ETH denominated in wei

        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        ConfirmPayment(_idPayment);
    }

    function cancelPayment(uint _idPayment) onlyOwner {
        doCancelPayment(_idPayment);
    }

    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment);

    }

    function multiConfirm(uint[] _idPayments) onlyOwner {
        for (uint i=0; i < _idPayments.length; i++) {
            doConfirmPayment(_idPayments[i]);
        }
    }

    function multiCancel(uint[] _idPayments) onlyOwner {
        for (uint i=0; i < _idPayments.length; i++) {
            doCancelPayment(_idPayments[i]);
        }
    }

    function nPayments() constant returns (uint) {
        return payments.length;
    }

    event ConfirmPayment(uint indexed idPayment);
    event CancelPayment(uint indexed idPayment);
    event AuthorizePayment(uint indexed idPayment, bytes32 indexed ref, address indexed dest, uint amount);
}
