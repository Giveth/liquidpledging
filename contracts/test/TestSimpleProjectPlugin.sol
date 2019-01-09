pragma solidity ^0.4.24;

import "../LiquidPledging.sol";

// simple liquidPledging plugin contract for testing whitelist
contract TestSimpleProjectPlugin {

    uint64 public idProject;
    bool initPending;

    event BeforeTransfer(uint64 pledgeAdmin, uint64 pledgeFrom, uint64 pledgeTo, uint64 context, uint amount);
    event AfterTransfer(uint64 pledgeAdmin, uint64 pledgeFrom, uint64 pledgeTo, uint64 context, uint amount);

    constructor() public {
        require(msg.sender != tx.origin); // Avoids being created directly by mistake.
        initPending = true;
    }

    function init(
        LiquidPledging liquidPledging,
        string name,
        string url,
        uint64 parentProject
    ) public {
        require(initPending);
        idProject = liquidPledging.addProject(name, url, address(this), parentProject, 0, ILiquidPledgingPlugin(this));
        initPending = false;
    }

    function beforeTransfer(
        uint64 pledgeAdmin,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external returns (uint maxAllowed) {
        require(!initPending);
        maxAllowed;
        emit BeforeTransfer(pledgeAdmin, pledgeFrom, pledgeTo, context, amount);
    }

    function afterTransfer(
        uint64 pledgeAdmin,
        uint64 pledgeFrom,
        uint64 pledgeTo,
        uint64 context,
        uint amount
    ) external {
        require(!initPending);
        emit AfterTransfer(pledgeAdmin, pledgeFrom, pledgeTo, context, amount);
    }

}
