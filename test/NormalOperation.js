/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require('ethereumjs-testrpc');
const Web3 = require('web3');
const chai = require('chai');
const liquidpledging = require('../index.js');
const assertFail = require('./helpers/assertFail');

const { utils } = Web3;

const LiquidPledging = liquidpledging.LiquidPledging(true);
const Vault = liquidpledging.Vault;
const assert = chai.assert;


const printState = async (liquidPledging) => {
  console.log(liquidPledging.b);
  const st = await liquidPledging.getState();
  console.log(JSON.stringify(st, null, 2));
};

const printBalances = async (liquidPledging) => {
  const st = await liquidPledging.getState();
  assert.equal(st.pledges.length, 13);
  for (let i = 1; i <= 12; i += 1) {
    console.log(i, Web3.utils.fromWei(st.pledges[i].amount));
  }
};

const readTest = async (liquidPledging) => {
  const t1 = await liquidPledging.test1();
  const t2 = await liquidPledging.test2();
  const t3 = await liquidPledging.test3();
  const t4 = await liquidPledging.test4();
  console.log('t1: ', t1.toNumber());
  console.log('t2: ', t2.toNumber());
  console.log('t3: ', t3.toNumber());
  console.log('t4: ', t4.toNumber());
};

describe('LiquidPledging test', () => {
  let web3;
  let accounts;
  let liquidPledging;
  let vault;
  let giver1;
  let giver2;
  let delegate1;
  let adminCampaign1;
  let adminCampaign2;
  let adminCampaign2a;
  let delegate2;
  before(async () => {
    const testrpc = TestRPC.server({
      ws: true,
      gasLimit: 5200000,
      total_accounts: 10,
    });

    testrpc.listen(8546, '127.0.0.1');

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    giver1 = accounts[1];
    delegate1 = accounts[2];
    adminCampaign1 = accounts[3];
    adminCampaign2 = accounts[4];
    adminCampaign2a = accounts[5];
    delegate2 = accounts[6];
    giver2 = accounts[7];
  });
  it('Should deploy LiquidPledging contract', async () => {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { gas: 5200000 });
    await vault.setLiquidPledging(liquidPledging.$address);
  }).timeout(6000);
  it('Should create a giver', async () => {
    await liquidPledging.addGiver('Giver1', 86400, 0, { from: giver1 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 1);
    const res = await liquidPledging.getPledgeAdmin(1);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], giver1);
    assert.equal(res[2], 'Giver1');
    assert.equal(res[3], 86400);
  }).timeout(6000);
  it('Should make a donation', async () => {
    await liquidPledging.donate(1, 1, { from: giver1, value: utils.toWei(1) });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 1);
    await liquidPledging.getPledge(1);
  }).timeout(6000);
  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 0, 0, { from: delegate1 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
    const res = await liquidPledging.getPledgeAdmin(2);
    assert.equal(res[0], 1); // Giver
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
  }).timeout(6000);
  it('Giver should delegate on the delegate', async () => {
    await liquidPledging.transfer(1, 1, utils.toWei(0.5), 2, { from: giver1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 2);
    const res1 = await liquidPledging.getPledge(1);
    assert.equal(res1[0], utils.toWei(0.5));
    const res2 = await liquidPledging.getPledge(2);
    assert.equal(res2[0], utils.toWei(0.5));
    assert.equal(res2[1], 1); // One delegate

    const d = await liquidPledging.getPledgeDelegate(2, 1);
    assert.equal(d[0], 2);
    assert.equal(d[1], delegate1);
    assert.equal(d[2], 'Delegate1');
  }).timeout(6000);
  it('Should create a 2 campaigns', async () => {
    await liquidPledging.addCampaign('Campaign1', adminCampaign1, 0, 86400, 0, { from: adminCampaign1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 3);
    const res = await liquidPledging.getPledgeAdmin(3);
    assert.equal(res[0], 2); // Campaign type
    assert.equal(res[1], adminCampaign1);
    assert.equal(res[2], 'Campaign1');
    assert.equal(res[3], 86400);
    assert.equal(res[4], 0);
    assert.equal(res[5], false);

    await liquidPledging.addCampaign('Campaign2', adminCampaign2, 0, 86400, 0, { from: adminCampaign2 });

    const nAdmins2 = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins2, 4);
    const res4 = await liquidPledging.getPledgeAdmin(4);
    assert.equal(res4[0], 2); // Campaign type
    assert.equal(res4[1], adminCampaign2);
    assert.equal(res4[2], 'Campaign2');
    assert.equal(res4[3], 86400);
    assert.equal(res4[4], 0);
    assert.equal(res4[5], false);
  }).timeout(6000);
  it('Delegate should assign to campaign1', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.transfer(2, 2, utils.toWei(0.2), 3, { from: delegate1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 3);
    const res3 = await liquidPledging.getPledge(3);
    assert.equal(res3[0], utils.toWei(0.2));
    assert.equal(res3[1], 1); // Owner
    assert.equal(res3[2], 1); // Delegates
    assert.equal(res3[3], 3); // Proposed Campaign
    assert.isAbove(utils.toDecimal(res3[4]), n + 86000);
    assert.equal(res3[5], 0); // Old Node
    assert.equal(res3[6], 0); // Not Paid
  }).timeout(6000);
  it('Giver should change his mind and assign half of it to campaign2', async () => {
    await liquidPledging.transfer(1, 3, utils.toWei(0.1), 4, { from: giver1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 4);
    const res3 = await liquidPledging.getPledge(3);
    assert.equal(res3[0], utils.toWei(0.1));
    const res4 = await liquidPledging.getPledge(4);
    assert.equal(res4[1], 4); // Owner
    assert.equal(res4[2], 0); // Delegates
    assert.equal(res4[3], 0); // Proposed Campaign
    assert.equal(res4[4], 0);
    assert.equal(res4[5], 2); // Old Node
    assert.equal(res4[6], 0); // Not Paid
  }).timeout(6000);
  it('After the time, the campaign1 should be able to spend part of it', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + 86401);
    await liquidPledging.withdraw(3, utils.toWei(0.05), { from: adminCampaign1 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 6);
    const res5 = await liquidPledging.getPledge(5);
    assert.equal(res5[0], utils.toWei(0.05));
    assert.equal(res5[1], 3); // Owner
    assert.equal(res5[2], 0); // Delegates
    assert.equal(res5[3], 0); // Proposed Campaign
    assert.equal(res5[4], 0);            // commit time
    assert.equal(res5[5], 2); // Old Node
    assert.equal(res5[6], 0); // Not Paid
    const res6 = await liquidPledging.getPledge(6);
    assert.equal(res6[0], utils.toWei(0.05));
    assert.equal(res6[1], 3); // Owner
    assert.equal(res6[2], 0); // Delegates
    assert.equal(res6[3], 0); // Proposed Campaign
    assert.equal(res6[4], 0);            // commit time
    assert.equal(res6[5], 2); // Old Node
    assert.equal(res6[6], 1); // Peinding paid Paid
  }).timeout(6000);
  it('Should collect the Ether', async () => {
    const initialBalance = await web3.eth.getBalance(adminCampaign1);

    await vault.confirmPayment(0);
    const finalBalance = await web3.eth.getBalance(adminCampaign1);

    const collected = utils.fromWei(utils.toBN(finalBalance).sub(utils.toBN(initialBalance)));

    assert.equal(collected, 0.05);

    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 7);
    const res7 = await liquidPledging.getPledge(7);
    assert.equal(res7[0], utils.toWei(0.05));
    assert.equal(res7[1], 3); // Owner
    assert.equal(res7[2], 0); // Delegates
    assert.equal(res7[3], 0); // Proposed Campaign
    assert.equal(res7[4], 0);            // commit time
    assert.equal(res7[5], 2); // Old Node
    assert.equal(res7[6], 2); // Peinding paid Paid
  }).timeout(6000);
  it('Admin of the campaign1 should be able to cancel campaign1', async () => {
    await liquidPledging.cancelCampaign(3, { from: adminCampaign1 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.admins[3].canceled, true);
  }).timeout(6000);
  it('Should not allow to withdraw from a canceled campaign', async () => {
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(utils.fromWei(st.pledges[5].amount), 0.05);
    await assertFail(async () => {
      await liquidPledging.withdraw(5, utils.toWei(0.01), { from: adminCampaign1 });
    });
  }).timeout(6000);
  it('Delegate should send part of this ETH to campaign2', async () => {
    await liquidPledging.transfer(2, 5, utils.toWei(0.03), 4, {
      $extraGas: 100000,
      from: delegate1,
    });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.pledges.length, 9);
    assert.equal(utils.fromWei(st.pledges[8].amount), 0.03);
    assert.equal(st.pledges[8].owner, 1);
    assert.equal(st.pledges[8].delegates.length, 1);
    assert.equal(st.pledges[8].delegates[0].id, 2);
    assert.equal(st.pledges[8].intendedCampaign, 4);
  }).timeout(6000);
  it('Giver should be able to send the remaining to campaign2', async () => {
    await liquidPledging.transfer(1, 5, utils.toWei(0.02), 4, { from: giver1, $extraGas: 100000 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.pledges.length, 9);
    assert.equal(utils.fromWei(st.pledges[5].amount), 0);
    assert.equal(utils.fromWei(st.pledges[4].amount), 0.12);
  }).timeout(6000);
  it('A subcampaign 2a and a delegate2 is created', async () => {
    await liquidPledging.addCampaign('Campaign2a', adminCampaign2a, 4, 86400, 0, { from: adminCampaign2 });
    await liquidPledging.addDelegate('Delegate2', 0, 0, { from: delegate2 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 6);
  }).timeout(6000);
  it('Campaign 2 delegate in delegate2', async () => {
    await liquidPledging.transfer(4, 4, utils.toWei(0.02), 6, { from: adminCampaign2 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.pledges.length, 10);
    assert.equal(utils.fromWei(st.pledges[9].amount), 0.02);
    assert.equal(utils.fromWei(st.pledges[4].amount), 0.1);
  }).timeout(6000);
  it('delegate2 assigns to projec2a', async () => {
    await liquidPledging.transfer(6, 9, utils.toWei(0.01), 5, { from: delegate2 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.pledges.length, 11);
    assert.equal(utils.fromWei(st.pledges[9].amount), 0.01);
    assert.equal(utils.fromWei(st.pledges[10].amount), 0.01);
  }).timeout(4000);
  it('campaign2a authorize to spend a litle', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + (86401 * 3));
    await liquidPledging.withdraw(10, utils.toWei(0.005), { from: adminCampaign2a });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.pledges.length, 13);
    assert.equal(utils.fromWei(st.pledges[10].amount), 0);
    assert.equal(utils.fromWei(st.pledges[11].amount), 0.005);
    assert.equal(utils.fromWei(st.pledges[12].amount), 0.005);
  }).timeout(4000);
  it('campaign2 is canceled', async () => {
    await liquidPledging.cancelCampaign(4, { from: adminCampaign2 });
  }).timeout(6000);
  it('campaign2 should not be able to confirm payment', async () => {
    await assertFail(async () => {
      await vault.confirmPayment(1);
    });
  }).timeout(6000);
  it('Should not be able to withdraw it', async () => {
    await assertFail(async () => {
      await liquidPledging.withdraw(12, utils.toWei(0.005), { from: giver1 });
    });
  }).timeout(6000);
  it('Should be able to cancel payment', async () => {
    // bug somewhere which will throw invalid op_code if we don't provide gas or extraGas
    await vault.cancelPayment(1, { $extraGas: 100000 });
    const st = await liquidPledging.getState();
    assert.equal(st.pledges.length, 13);
    assert.equal(utils.fromWei(st.pledges[2].amount), 0.31);
    assert.equal(utils.fromWei(st.pledges[11].amount), 0);
    assert.equal(utils.fromWei(st.pledges[12].amount), 0);
  }).timeout(6000);
  it('original owner should recover the remaining funds', async () => {
    await liquidPledging.withdraw(1, utils.toWei(0.5), { from: giver1 });
    await liquidPledging.withdraw(2, utils.toWei(0.31), { from: giver1 });
    await liquidPledging.withdraw(4, utils.toWei(0.1), { $extraGas: 100000, from: giver1 });

    await liquidPledging.withdraw(8, utils.toWei(0.03), { $extraGas: 100000, from: giver1 });
    await liquidPledging.withdraw(9, utils.toWei(0.01), { $extraGas: 100000, from: giver1 });

    const initialBalance = await web3.eth.getBalance(giver1);
    await vault.multiConfirm([2, 3, 4, 5, 6]);

    const finalBalance = await web3.eth.getBalance(giver1);
    const collected = utils.fromWei(utils.toBN(finalBalance).sub(utils.toBN(initialBalance)));

    assert.equal(collected, 0.95);
  }).timeout(10000);
  it('Should make a donation and create giver', async () => {
    const oldNPledges = await liquidPledging.numberOfPledges();
    const oldNAdmins = await liquidPledging.numberOfPledgeAdmins();
    await liquidPledging.donate(0, 1, { from: giver2, value: utils.toWei(1) });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(utils.toDecimal(nPledges), utils.toDecimal(oldNPledges) + 1);
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(utils.toDecimal(nAdmins), utils.toDecimal(oldNAdmins) + 1);
    const res = await liquidPledging.getPledgeAdmin(nAdmins);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], giver2);
    assert.equal(res[2], '');
    assert.equal(res[3], 259200); // default to 3 day commitTime
  }).timeout(6000);
});
