/* global artifacts */
/* global contract */
/* global web3 */
/* global assert */

/* eslint-disable no-await-in-loop */

const assertFail = require('./helpers/assertFail');
const eventArgsOf = require('./helpers/eventArgsOf');
const LiquidPledgingState = require('./helpers/liquidPledgingState')

const LPVault = artifacts.require("../contracts/LPVault.sol");
const LiquidPledgingMock = artifacts.require("../contracts/LiquidPledgingMock.sol");
const LPFactory = artifacts.require("../contracts/LPFactory.sol");
const Kernel = artifacts.require("../node_modules/@aragon/os/contract/kernel/Kernel.sol");
const ACL = artifacts.require("../node_modules/@aragon/os/contract/acl/ACL.sol");
const StandardToken = artifacts.require("../node_modules/@aragon/os/contract/lib/zeppelin/token/StandardToken.sol");

const { utils } = web3;

contract('LiquidPledging test', accounts => {

  let maxGas

  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let giver1;
  let giver2;
  let delegate1;
  let adminProject1;
  let adminProject2;
  let adminProject2a;
  let adminProject3;
  let delegate2;
  let escapeHatchDestination;
  let escapeHatchCaller;
  let acl;
  let giver1Token;
  let giver2Token;

  before(async () => {

    giver1 = accounts[1];
    delegate1 = accounts[2];
    adminProject1 = accounts[3];
    adminProject2 = accounts[4];
    adminProject2a = accounts[5];
    delegate2 = accounts[6];
    giver2 = accounts[7];
    adminProject3 = accounts[8];
    escapeHatchDestination = accounts[9];
    escapeHatchCaller = accounts[10];

  });


  
  it('Should deploy LiquidPledging contract', async () => {
    
    var block = web3.eth.getBlock("latest");
    maxGas =  block.gasLimit;

    const baseVault = await LPVault.new(escapeHatchDestination);
    const baseLP = await LiquidPledgingMock.new(escapeHatchDestination, { gas: maxGas });
    lpFactory = await LPFactory.new(baseVault.address, baseLP.address);

    assert.isAbove(Number(await baseVault.getInitializationBlock()), 0);
    assert.isAbove(Number(await baseLP.getInitializationBlock()), 0);

    const r = await lpFactory.newLP(accounts[0], escapeHatchDestination);
    const vaultAddress = eventArgsOf(r,'DeployVault').vault;
    vault = await LPVault.at(vaultAddress);

    const lpAddress = eventArgsOf(r,'DeployLiquidPledging').liquidPledging;
    liquidPledging = await LiquidPledgingMock.at(lpAddress);
    liquidPledgingState = new LiquidPledgingState(liquidPledging);


    // set permissions
    const kernel = Kernel.at(await liquidPledging.kernel());
    acl = ACL.at(await kernel.acl());
    await acl.createPermission(accounts[0], vault.address, await vault.CANCEL_PAYMENT_ROLE(), accounts[0], {gas: maxGas});
    await acl.createPermission(accounts[0], vault.address, await vault.CONFIRM_PAYMENT_ROLE(), accounts[0], {gas: maxGas});
    await acl.grantPermission(escapeHatchCaller, vault.address, await vault.ESCAPE_HATCH_CALLER_ROLE(), {gas: maxGas});
    await acl.revokePermission(accounts[0], vault.address, await vault.ESCAPE_HATCH_CALLER_ROLE(), {gas: maxGas});

    giver1Token = await StandardToken.new();
    giver2Token = await StandardToken.new();
    await giver1Token.mint(giver1, web3.toWei('1000'));
    await giver2Token.mint(giver2, web3.toWei('1000'));

    await giver1Token.approve(liquidPledging.address, "0xFFFFFFFFFFFFFFFF", {from: giver1});
    await giver2Token.approve(liquidPledging.address, "0xFFFFFFFFFFFFFFFF", {from: giver2});
  });

  it('Should create a giver', async () => {
    await liquidPledging.contract.addGiver['string,string,uint64,address']('Giver1', 'URLGiver1', 86400, "0x0", { from: giver1, gas: maxGas });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 1);

    const res = await liquidPledging.getPledgeAdmin(1);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], giver1);
    assert.equal(res[2], 'Giver1');
    assert.equal(res[3], 'URLGiver1');
    assert.equal(res[4], 86400);
  });

  it('Should make a donation', async () => {
    const r = await liquidPledging.donate(1, 1, giver1Token.address, web3.toWei('1'), { from: giver1, gas: maxGas });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 1);

    const p = await liquidPledgingState.getPledge(1);
    assert.equal(p.amount, web3.toWei('1'));
    assert.equal(p.owner, 1);
    const vaultBal = await giver1Token.balanceOf(vault.address);
    const giver1Bal = await giver1Token.balanceOf(giver1);
    assert.equal(vaultBal, web3.toWei('1'))
    assert.equal(giver1Bal, web3.toWei('999'))

  });

  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 'URLDelegate1', 0, 0, { from: delegate1 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
    const res = await liquidPledging.getPledgeAdmin(2);
    assert.equal(res[0], 1); // Giver
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
    assert.equal(res[3], 'URLDelegate1');
    assert.equal(res[4], 0);
  });

  it('Giver should delegate on the delegate', async () => {
    await liquidPledging.transfer(1, 1, web3.toWei('0.5'), 2, { from: giver1, gas: maxGas });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 2);
    const res1 = await liquidPledgingState.getPledge(1);
    assert.equal(res1.amount, web3.toWei('0.5'));
    const res2 = await liquidPledgingState.getPledge(2);
    assert.equal(res2.amount, web3.toWei('0.5'));
    assert.equal(res2.owner, 1); // One delegate

    const d = await liquidPledging.getPledgeDelegate(2, 1);
    assert.equal(d[0], 2);
    assert.equal(d[1], delegate1);
    assert.equal(d[2], 'Delegate1');
  });
  it('Should create a 2 projects', async () => {
    await liquidPledging.addProject('Project1', 'URLProject1', adminProject1, 0, 86400, 0, { from: adminProject1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 3);
    const res = await liquidPledging.getPledgeAdmin(3);
    assert.equal(res[0], 2); // Project type
    assert.equal(res[1], adminProject1);
    assert.equal(res[2], 'Project1');
    assert.equal(res[3], 'URLProject1');
    assert.equal(res[4], 86400);
    assert.equal(res[5], 0);
    assert.equal(res[6], false);

    await liquidPledging.addProject('Project2', 'URLProject2', adminProject2, 0, 86400, 0, { from: adminProject2 });

    const nAdmins2 = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins2, 4);
    const res4 = await liquidPledging.getPledgeAdmin(4);
    assert.equal(res4[0], 2); // Project type
    assert.equal(res4[1], adminProject2);
    assert.equal(res4[2], 'Project2');
    assert.equal(res4[3], 'URLProject2');
    assert.equal(res4[4], 86400);
    assert.equal(res4[5], 0);
    assert.equal(res4[6], false);
  });
  it('Delegate should assign to project1', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.transfer(2, 2, web3.toWei('0.2'), 3, { from: delegate1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 3);
    const res3 = await liquidPledgingState.getPledge(3);
    assert.equal(res3.amount, web3.toWei('0.2'));
    assert.equal(res3.owner, 1);
    assert.equal(res3.nDelegates, 1);
    assert.equal(res3.intendedProject, 3);
    assert.isAbove(res3.commitTime.toNumber(), n + 86000);
    assert.equal(res3.oldPledge, 0);
    assert.equal(res3.token, giver1Token.address);
    assert.equal(res3.pledgeState, 'Pledged'); // Not Paid
  });
  it('Giver should change his mind and assign half of it to project2', async () => {
    await liquidPledging.transfer(1, 3, web3.toWei('0.1'), 4, { from: giver1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 4);
    const res3 = await liquidPledgingState.getPledge(3);
    assert.equal(res3.amount, web3.toWei('0.1'));
    const res4 = await liquidPledgingState.getPledge(4);
    assert.equal(res4.owner, 4);
    assert.equal(res4.nDelegates, 0);
    assert.equal(res4.intendedProject, 0);
    assert.equal(res4.commitTime, 0);
    assert.equal(res4.oldPledge, 2);
    assert.equal(res4.token, giver1Token.address);
    assert.equal(res4.pledgeState, 'Pledged'); // Not Paid
  });
  it('After the time, the project1 should be able to spend part of it', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + 86401, {gas: maxGas});
    await liquidPledging.withdraw(3, web3.toWei('0.05'), { from: adminProject1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 6);
    const res5 = await liquidPledgingState.getPledge(5);
    assert.equal(res5.amount, web3.toWei('0.05'));
    assert.equal(res5.owner, 3);
    assert.equal(res5.nDelegates, 0);
    assert.equal(res5.intendedProject, 0);
    assert.equal(res5.commitTime, 0);
    assert.equal(res5.oldPledge, 2);
    assert.equal(res5.token, giver1Token.address);
    assert.equal(res5.pledgeState, 'Pledged'); // Not Paid
    const res6 = await liquidPledgingState.getPledge(6);
    assert.equal(res6.amount, web3.toWei('0.05'));
    assert.equal(res6.owner, 3);
    assert.equal(res6.nDelegates, 0);
    assert.equal(res6.intendedProject, 0);
    assert.equal(res6.commitTime, 0);
    assert.equal(res6.oldPledge, 2);
    assert.equal(res6.token, giver1Token.address);
    assert.equal(res6.pledgeState, 'Paying'); // Pending
  });

  it('Should collect the token', async () => {
    const initialBalance = await giver1Token.balanceOf(adminProject1);

    await vault.confirmPayment(0, {gas: maxGas});
    const finalBalance = await giver1Token.balanceOf(adminProject1);

    const collected = web3.fromWei(web3.toBigNumber(finalBalance).sub(web3.toBigNumber(initialBalance)));

    assert.equal(collected, 0.05);

    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 7);
    const res7 = await liquidPledgingState.getPledge(7);
    assert.equal(res7.amount, web3.toWei('0.05'));
    assert.equal(res7.owner, 3);
    assert.equal(res7.nDelegates, 0);
    assert.equal(res7.intendedProject, 0);
    assert.equal(res7.commitTime, 0);
    assert.equal(res7.oldPledge, 2);
    assert.equal(res7.token, giver1Token.address);
    assert.equal(res7.pledgeState, 'Paid'); // Paid
  });

  it('Admin of the project1 should be able to cancel project1', async () => {
    await liquidPledging.cancelProject(3, { from: adminProject1, gas: maxGas });
    const st = await liquidPledgingState.getState();
    assert.equal(st.admins[3].canceled, true);
  });

  it('Should not allow to withdraw from a canceled project', async () => {
    const p = await liquidPledgingState.getPledge(5);
    assert.equal(web3.fromWei(p.amount), 0.05);

    await assertFail(
      liquidPledging.withdraw(5, web3.toWei('0.01'), { from: adminProject1, gas: maxGas })
    );
  });
  it('Delegate should send part of this ETH to project2', async () => {
    await liquidPledging.transfer(2, 5, web3.toWei('0.03'), 4, {from: delegate1, gas: maxGas});
    const st = await liquidPledgingState.getState(liquidPledging);

    assert.equal(st.pledges.length, 9);
    assert.equal(web3.fromWei(st.pledges[8].amount), 0.03);
    assert.equal(st.pledges[8].owner, 1);
    assert.equal(st.pledges[8].delegates.length, 1);
    assert.equal(st.pledges[8].delegates[0].id, 2);
    assert.equal(st.pledges[8].intendedProject, 4);
  });

  it('Giver should be able to send the remaining to project2', async () => {
    await liquidPledging.transfer(1, 5, web3.toWei('0.02'), 4, { from: giver1, gas: maxGas });
    const st = await liquidPledgingState.getState(liquidPledging);
    assert.equal(st.pledges.length, 9);
    assert.equal(web3.fromWei(st.pledges[5].amount), 0);
    assert.equal(web3.fromWei(st.pledges[4].amount), 0.12);
  });
  it('A subproject 2a and a delegate2 is created', async () => {
    await liquidPledging.addProject('Project2a', 'URLProject2a', adminProject2a, 4, 86400, 0, { from: adminProject2 });
    await liquidPledging.addDelegate('Delegate2', 'URLDelegate2', 0, 0, { from: delegate2 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 6);
  });
  it('Project 2 delegate in delegate2', async () => {
    await liquidPledging.transfer(4, 4, web3.toWei('0.02'), 6, { from: adminProject2, gas: maxGas});
    const st = await liquidPledgingState.getState();
    assert.equal(st.pledges.length, 10);
    assert.equal(web3.fromWei(st.pledges[9].amount), 0.02);
    assert.equal(web3.fromWei(st.pledges[4].amount), 0.1);
  });
  it('delegate2 assigns to projec2a', async () => {
    await liquidPledging.transfer(6, 9, web3.toWei('0.01'), 5, { from: delegate2, gas: maxGas });
    const st = await liquidPledgingState.getState(liquidPledging);
    assert.equal(st.pledges.length, 11);
    assert.equal(web3.fromWei(st.pledges[9].amount), 0.01);
    assert.equal(web3.fromWei(st.pledges[10].amount), 0.01);
  });
  it('project2a authorize to spend a litle', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + (86401 * 3), {gas: maxGas});
    await liquidPledging.withdraw(10, web3.toWei('0.005'), { from: adminProject2a, gas: maxGas });
    const st = await liquidPledgingState.getState(liquidPledging);
    assert.equal(st.pledges.length, 13);
    assert.equal(web3.fromWei(st.pledges[10].amount), 0);
    assert.equal(web3.fromWei(st.pledges[11].amount), 0.005);
    assert.equal(web3.fromWei(st.pledges[12].amount), 0.005);
  });
  it('project2 is canceled', async () => {
    await liquidPledging.cancelProject(4, { from: adminProject2, gas: maxGas });
  });
  it('Should not be able to withdraw it', async () => {
    await assertFail(
      liquidPledging.withdraw(12, web3.toWei('0.005'), { from: giver1, gas: maxGas })
    );
  });
  it('Should be able to cancel payment', async () => {
    // bug somewhere which will throw invalid op_code if we don't provide gas or extraGas
    await vault.cancelPayment(1, { gas: maxGas });
    const st = await liquidPledgingState.getState();
    assert.equal(st.pledges.length, 13);
    assert.equal(web3.fromWei(st.pledges[2].amount), 0.31);
    assert.equal(web3.fromWei(st.pledges[11].amount), 0);
    assert.equal(web3.fromWei(st.pledges[12].amount), 0);
  });
  it('original owner should recover the remaining funds', async () => {
    const pledges = [
      { amount: web3.toWei('0.5'), id: 1 },
      { amount: web3.toWei('0.31'), id: 2 },
      { amount: web3.toWei('0.1'), id: 4 },
      { amount: web3.toWei('0.03'), id: 8 },
      { amount: web3.toWei('0.01'), id: 9 },
    ];

    // .substring is to remove the 0x prefix on the toHex result
    const encodedPledges = pledges.map(p => {
      return '0x' + web3.padLeft(web3.toHex(p.amount).substring(2), 48) + web3.padLeft(web3.toHex(p.id).substring(2), 16);
    });

    await liquidPledging.mWithdraw(encodedPledges, { from: giver1, gas: maxGas });

    const initialBalance = await giver1Token.balanceOf(giver1);
    await vault.multiConfirm([2, 3, 4, 5, 6], {gas: maxGas});

    const finalBalance = await giver1Token.balanceOf(giver1);
    const collected = web3.fromWei(web3.toBigNumber(finalBalance).sub(web3.toBigNumber(initialBalance)));

    assert.equal(collected, 0.95);
  });

  it('Should make a donation and create giver', async () => {
    const oldNPledges = await liquidPledging.numberOfPledges();
    const oldNAdmins = await liquidPledging.numberOfPledgeAdmins();
    await liquidPledging.contract.addGiverAndDonate['uint64,address,uint256'](1, giver2Token.address, web3.toWei('1'), { from: giver2, gas: maxGas });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(web3.toDecimal(nPledges), web3.toDecimal(oldNPledges) + 2);
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(web3.toDecimal(nAdmins), web3.toDecimal(oldNAdmins) + 1);
    const res = await liquidPledging.getPledgeAdmin(nAdmins);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], giver2);
    assert.equal(res[2], '');
    assert.equal(res[3], '');
    assert.equal(res[4], 259200); // default to 3 day commitTime
    const giver2Bal = await giver2Token.balanceOf(giver2);
    assert.equal(giver2Bal, web3.toWei('999'));
  });

  it('Should allow childProject with different parentProject owner', async () => {
    const nAdminsBefore = await liquidPledging.numberOfPledgeAdmins();
    await liquidPledging.addProject('Project3', 'URLProject3', adminProject3, 4, 86400, 0, { from: adminProject3 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, web3.toDecimal(nAdminsBefore) + 1);
  });

  it('should throw if projectLevel > 20', async () => {
    let nAdmins = await liquidPledging.numberOfPledgeAdmins();

    await liquidPledging.addProject('ProjectLevel0', '', adminProject1, 0, 86400, 0, { from: adminProject1, gas: maxGas});

    for (let i = 2; i <= 20; i++) {
      await liquidPledging.addProject(`ProjectLevel${i}`, '', adminProject1, ++nAdmins, 86400, 0, { from: adminProject1, gas: maxGas });
    }

    await assertFail(
      liquidPledging.addProject('ProjectLevel21', '', adminProject1, ++nAdmins, 86400, 0, { from: adminProject1, gas: maxGas })
    );
  });

  it('should prevent donation to 0 receiverId', async () => {
    await assertFail(liquidPledging.donate(1, 0, giver1Token.address, 1, { from: giver1, gas: maxGas }));
  });

  it('should prevent donation from 0 giverId', async () => {
    await assertFail(liquidPledging.donate(0, 1, giver1Token.address, 1, { from: giver1,gas: maxGas }));
  });

  it('should donate on behalf of another addy', async () => {
    const oldNPledges = await liquidPledging.numberOfPledges();
    const oldNAdmins = await liquidPledging.numberOfPledgeAdmins();
    const preGiver1Bal = await giver1Token.balanceOf(giver1);

    await liquidPledging.addGiverAndDonate(1, accounts[8], giver1Token.address, 11, { from: giver1, gas: maxGas });

    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(web3.toDecimal(nPledges), web3.toDecimal(oldNPledges) + 1);

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(web3.toDecimal(nAdmins), web3.toDecimal(oldNAdmins) + 1);

    const res = await liquidPledging.getPledgeAdmin(nAdmins);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], accounts[8]);
    assert.equal(res[2], '');
    assert.equal(res[3], '');
    assert.equal(res[4], 259200); // default to 3 day commitTime

    const giver1Bal = await giver1Token.balanceOf(giver1);
    assert.equal(new web3.toBigNumber(preGiver1Bal).sub(11).toString(), giver1Bal);
  });
  
});
