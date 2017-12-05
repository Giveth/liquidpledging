pragma solidity ^0.4.11;

/// @title LPVault
/// @author Jordi Baylina
/// @notice This contract holds ether securely for liquid pledging systems. For
///  this iteration the funds will come straight from the Giveth Multisig as a
///  safety precaution, but once fully tested and optimized this contract will
///  be a safe place to store funds equipped with optional variable time delays
///  to allow for an optional escape hatch to be implemented
import "./Owned.sol";

/// @dev `LiquidPledging` is a basic interface to allow the `LPVault` contract
///  to confirm and cancel payments in the `LiquidPledging` contract.
contract LiquidPledging {
    function confirmPayment(uint64 idPledge, uint amount) public;
    function cancelPayment(uint64 idPledge, uint amount) public;
}


/// @dev `LPVault` is a higher level contract built off of the `Owned`
///  contract that holds funds for the liquid pledging system.
contract LPVault is Owned {

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

    // @dev An array that contains all the payments for this LPVault
    Payment[] public payments;

    /// @dev `liquidPledging` is the only address that can call a function with
    ///  this modifier
    modifier onlyLiquidPledging() {
        require(msg.sender == address(liquidPledging));
        _;
    }
    /// @dev USED FOR TESTING???
    function VaultMock() public pure {

    }

    function () public payable {

    }

    /// @notice `setLiquidPledging` is used to attach a specific liquid pledging
    ///  instance to this LPvault. Keep in mind this isn't a single pledge but
    ///  instead an entire liquid pledging contract.
    /// @param _newLiquidPledging A full liquid pledging contract
    function setLiquidPledging(address _newLiquidPledging) public onlyOwner {
        require(address(liquidPledging) == 0x0);
        liquidPledging = LiquidPledging(_newLiquidPledging);
    }

    /// @notice `setAutopay` is used to toggle whether the LPvault will
    ///  automatically confirm a payment after the payment has been authorized.
    /// @param _automatic If true payments will confirm automatically
    function setAutopay(bool _automatic) public onlyOwner {
        autoPay = _automatic;
    }

    /// @notice `authorizePayment` is used in order to approve a payment 
    ///  from the liquid pledging contract. Whenever a project or other address
    ///  needs to receive a payment it needs to be authorized with this contract.
    /// @param _ref This parameter is used to reference details about the
    ///  payment from another contract.
    /// @param _dest This is the address that payments will end up being sent to
    /// @param _amount This is the amount that the payment is being authorized
    ///  for.
    function authorizePayment(
        bytes32 _ref,
        address _dest,
        uint _amount ) public onlyLiquidPledging returns (uint) {
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

    /// @notice `confirmPayment` is a basic function used to allow the
    ///  owner of the vault to initiate a payment confirmation. Since 
    ///  `authorizePayment` is the only pay to populate the `payments` array
    ///  this is generally used when `autopay` is `false` after a payment has
    ///  has been authorized.
    /// @param _idPayment Array lookup for the payment.
    function confirmPayment(uint _idPayment) public onlyOwner {
        doConfirmPayment(_idPayment);
    }

    /// @notice `doConfirmPayment` is used to actually initiate a payment
    ///  to the final destination. All of the payment information should be
    ///  set before calling this function.
    /// @param _idPayment Array lookup for the payment.
    function doConfirmPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Paid;
        liquidPledging.confirmPayment(uint64(p.ref), p.amount);

        p.dest.transfer(p.amount);  // only ETH denominated in wei

        ConfirmPayment(_idPayment);
    }

    /// @notice `cancelPayment` is used when `autopay` is `false` in order
    ///  to allow the owner to cancel a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.
    function cancelPayment(uint _idPayment) public onlyOwner {
        doCancelPayment(_idPayment);
    }

    /// @notice `doCancelPayment` This carries out the task of actually
    ///  canceling a payment instead of confirming it.
    /// @param _idPayment Array lookup for the payment.    
    function doCancelPayment(uint _idPayment) internal {
        require(_idPayment < payments.length);
        Payment storage p = payments[_idPayment];
        require(p.state == PaymentStatus.Pending);

        p.state = PaymentStatus.Canceled;

        liquidPledging.cancelPayment(uint64(p.ref), p.amount);

        CancelPayment(_idPayment);

    }

    /// @notice `multiConfirm` allows for more efficient confirmation of
    ///  multiple payments.
    /// @param _idPayments An array of multiple payment ids
    function multiConfirm(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doConfirmPayment(_idPayments[i]);
        }
    }

    /// @notice `multiCancel` allows for more efficient cancellation of
    ///  multiple payments.
    /// @param _idPayments An array of multiple payment ids
    function multiCancel(uint[] _idPayments) public onlyOwner {
        for (uint i = 0; i < _idPayments.length; i++) {
            doCancelPayment(_idPayments[i]);
        }
    }

    /// @notice `nPayments` Basic getter to return the number of payments
    ///  currently held in the system. Since payments are not removed from
    ///  the array this represents all payments over all time.
    function nPayments() constant public returns (uint) {
        return payments.length;
    }

    event ConfirmPayment(uint indexed idPayment);
    event CancelPayment(uint indexed idPayment);
    event AuthorizePayment(uint indexed idPayment, bytes32 indexed ref, address indexed dest, uint amount);
}