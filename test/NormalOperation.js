const LiquidPledging = artifacts.require("LiquidPledgingMock");
const Vault = artifacts.require("Vault");

contract("LiquidPledging", (accounts) => {
    let liquidPledging;
    let vault;
    let donor1 = accounts[0];
    let delegate1 = accounts[1];
    let adminProject1 = accounts[2];
    let adminProject2 = accounts[3];
    let reviewer = accounts[4];
    it("Should deploy LiquidPledgin contract", async () => {
        vault = await Vault.new();
        liquidPledging = await LiquidPledging.new(vault.address);
        await vault.setLiquidPledging(liquidPledging.address);
    });
    it("Should create a donor", async () => {
        await liquidPledging.addDonor("Donor1", 86400, {from: donor1});
        const nManagers = await liquidPledging.numberOfNoteManagers();
        assert.equal(nManagers, 1);
        const res = await liquidPledging.getNoteManager(1);
        assert.equal(res[0],  0); // Donor
        assert.equal(res[1],  donor1);
        assert.equal(res[2],  "Donor1");
        assert.equal(res[3],  86400);
    });
    it("Should make a donation", async () => {
        await liquidPledging.donate(1, 1, {from: donor1, value: web3.toWei(1)});
        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 1);
        const res = await liquidPledging.getNote(1);
    });
    it("Should create a delegate", async () => {
        await liquidPledging.addDelegate("Delegate1", {from: delegate1});
        const nManagers = await liquidPledging.numberOfNoteManagers();
        assert.equal(nManagers, 2);
        const res = await liquidPledging.getNoteManager(2);
        assert.equal(res[0],  1); // Donor
        assert.equal(res[1],  delegate1);
        assert.equal(res[2],  "Delegate1");
    });
    it("Donor should delegate on the delegate ", async () => {
        await liquidPledging.transfer(1, 1, web3.toWei(0.5), 2);
        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 2);
        const res1 = await liquidPledging.getNote(1);
        assert.equal(res1[0].toNumber(), web3.toWei(0.5));
        const res2 = await liquidPledging.getNote(2);
        assert.equal(res2[0].toNumber(), web3.toWei(0.5));
        assert.equal(res2[1].toNumber(), 1); // One delegate

        const d = await liquidPledging.getNoteDelegate(2, 1);
        assert.equal(d[0], 2);
        assert.equal(d[1], delegate1);
        assert.equal(d[2], "Delegate1");
    });
    it("Should create a 2 projects", async () => {
        await liquidPledging.addProject("Project1", reviewer, 86400, {from: adminProject1});

        const nManagers = await liquidPledging.numberOfNoteManagers();
        assert.equal(nManagers, 3);
        const res = await liquidPledging.getNoteManager(3);
        assert.equal(res[0],  2); // Project type
        assert.equal(res[1],  adminProject1);
        assert.equal(res[2],  "Project1");
        assert.equal(res[3],  86400);
        assert.equal(res[4],  reviewer);
        assert.equal(res[5],  false);

        await liquidPledging.addProject("Project2", reviewer, 86400, {from: adminProject2});

        const nManagers2 = await liquidPledging.numberOfNoteManagers();
        assert.equal(nManagers2, 4);
        const res4 = await liquidPledging.getNoteManager(4);
        assert.equal(res4[0],  2); // Project type
        assert.equal(res4[1],  adminProject2);
        assert.equal(res4[2],  "Project2");
        assert.equal(res4[3],  86400);
        assert.equal(res4[4],  reviewer);
        assert.equal(res4[5],  false);
    });
    it("Delegate should assign to project1", async () => {
        const n = Math.floor(new Date().getTime() / 1000);
        await liquidPledging.transfer(2, 2, web3.toWei(0.2), 3, {from: delegate1});
        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 3);
        const res3 = await liquidPledging.getNote(3);
        assert.equal(res3[0].toNumber(), web3.toWei(0.2));
        assert.equal(res3[1].toNumber(), 1); // Owner
        assert.equal(res3[2].toNumber(), 1); // Delegates
        assert.equal(res3[3].toNumber(), 3); // Proposed Project
        assert.isAbove(res3[4], n + 86000);
        assert.equal(res3[5].toNumber(), 0); // Old Node
        assert.equal(res3[6].toNumber(), 0); // Not Paid
    });
    it("Donor should change his mind and assign half of it to project2", async () => {
        const n = Math.floor(new Date().getTime() / 1000);
        await liquidPledging.transfer(1, 3, web3.toWei(0.1), 4, {from: donor1});
        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 4);
        const res3 = await liquidPledging.getNote(3);
        assert.equal(res3[0].toNumber(), web3.toWei(0.1));
        const res4 = await liquidPledging.getNote(4);
        assert.equal(res4[1].toNumber(), 4); // Owner
        assert.equal(res4[2].toNumber(), 0); // Delegates
        assert.equal(res4[3].toNumber(), 0); // Proposed Project
        assert.equal(res4[4], 0);
        assert.equal(res4[5].toNumber(), 2); // Old Node
        assert.equal(res4[6].toNumber(), 0); // Not Paid
    });
    it("After the time, the project1 should be able to spend part of it", async () => {
        const n = Math.floor(new Date().getTime() / 1000);
        await liquidPledging.setMockedTime(n + 86401);
        await liquidPledging.withdraw(3, web3.toWei(0.05), {from: adminProject1});
        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 6);
        const res5 = await liquidPledging.getNote(5);
        assert.equal(res5[0].toNumber(), web3.toWei(0.05));
        assert.equal(res5[1].toNumber(), 3); // Owner
        assert.equal(res5[2].toNumber(), 0); // Delegates
        assert.equal(res5[3].toNumber(), 0); // Proposed Project
        assert.equal(res5[4], 0);            // commit time
        assert.equal(res5[5].toNumber(), 2); // Old Node
        assert.equal(res5[6].toNumber(), 0); // Not Paid
        const res6 = await liquidPledging.getNote(6);
        assert.equal(res6[0].toNumber(), web3.toWei(0.05));
        assert.equal(res6[1].toNumber(), 3); // Owner
        assert.equal(res6[2].toNumber(), 0); // Delegates
        assert.equal(res6[3].toNumber(), 0); // Proposed Project
        assert.equal(res6[4], 0);            // commit time
        assert.equal(res6[5].toNumber(), 2); // Old Node
        assert.equal(res6[6].toNumber(), 1); // Peinding paid Paid
    });
    it("Should collect the Ether", async () => {
        const initialBalance = await web3.eth.getBalance(adminProject1);

        await vault.confirmPayment(0);
        const finalBalance = await web3.eth.getBalance(adminProject1);

        const collected = web3.fromWei(finalBalance.sub(initialBalance)).toNumber();

        assert.equal(collected, 0.05);

        const nNotes = await liquidPledging.numberOfNotes();
        assert.equal(nNotes.toNumber(), 7);
        const res7 = await liquidPledging.getNote(7);
        assert.equal(res7[0].toNumber(), web3.toWei(0.05));
        assert.equal(res7[1].toNumber(), 3); // Owner
        assert.equal(res7[2].toNumber(), 0); // Delegates
        assert.equal(res7[3].toNumber(), 0); // Proposed Project
        assert.equal(res7[4], 0);            // commit time
        assert.equal(res7[5].toNumber(), 2); // Old Node
        assert.equal(res7[6].toNumber(), 2); // Peinding paid Paid

    });
    it("Reviewer should be able to cancel project1", async () => {

    });
    it("Delegate should send part of this ETH to project2", async () => {

    });
    it("Owner should be able to send the remaining to project2", async () => {

    });
    it("A subproject 2a and a delegate2 is created", async () => {

    });
    it("Project 2 delegate in delegate2", async () => {

    });
    it("delegate2 assigns to projec2a", async () => {

    });
    it("project2a spends on a while", async () => {

    });
    it("project2 is canceled", async () => {

    });
    it("original owner should recover the remaining funds", async () => {

    });

});
