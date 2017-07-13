pragma solidity ^0.4.11;

import "./Owned.sol";

contract LiquidPledging {
    function confirmPayment(uint64 idNote, uint amount);
    function cancelPayment(uint64 idNote, uint amount);
}

contract Vault is Owned {

    LiquidPledging public liquidPledging;
    bool public autoPay;

    enum PaymentState {
        Pending,
        Paid,
        Canceled
    }

    struct Payment {
        PaymentState state;
        bytes32 ref;
        address dest;
        uint amount;
    }

    Payment[] public payments;

    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }

    function VaultMock() {

    }

    function () payable {

    }

    function setLiquidPledging(address _newLiquidPledging) onlyOwner {
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

    function setAutopay(bool _automatic) onlyOwner {
        autoPay = _automatic;
    }


    function authorizePayment(bytes32 _ref, address _dest, uint _amount) onlyLiquidPledging returns (uint) {
        uint idPayment = payments.length;
        payments.length ++;
        payments[idPayment].state = PaymentState.Pending;
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
        require(p.state == PaymentState.Pending);

        p.state = PaymentState.Paid;
        p.dest.transfer(p.amount);

        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        ConfirmPayment(_idPayment);
    }

    function cancelPayment(uint _idPayment) onlyOwner {
        doCancelPayment(_idPayment);
    }

    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentState.Pending);

        p.state = PaymentState.Canceled;

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
