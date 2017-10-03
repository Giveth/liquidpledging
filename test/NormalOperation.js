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
  assert.equal(st.notes.length, 13);
  for (let i = 1; i <= 12; i += 1) {
    console.log(i, Web3.utils.fromWei(st.notes[i].amount));
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

const startTestrpc = opts => new Promise((resolve) => {
  const testrpc = TestRPC.server(opts);

  testrpc.listen(8546, '127.0.0.1', (err) => {
    resolve();
  });
});

describe('LiquidPledging test', () => {
  let web3;
  let accounts;
  let liquidPledging;
  let vault;
  let donor1;
  let donor2;
  let delegate1;
  let adminProject1;
  let adminProject2;
  let adminProject2a;
  let delegate2;
  before(async () => {
    await startTestrpc({
      ws: true,
      gasLimit: 5200000,
      total_accounts: 10,
    });

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    donor1 = accounts[1];
    delegate1 = accounts[2];
    adminProject1 = accounts[3];
    adminProject2 = accounts[4];
    adminProject2a = accounts[5];
    delegate2 = accounts[6];
    donor2 = accounts[7];
  });
  it('Should deploy LiquidPledging contract', async () => {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { gas: 5200000 });
    await vault.setLiquidPledging(liquidPledging.$address);
  }).timeout(6000);
  it('Should create a donor', async () => {
    await liquidPledging.addDonor('Donor1', 86400, 0, { from: donor1 });
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 1);
    const res = await liquidPledging.getNoteManager(1);
    assert.equal(res[0], 0); // Donor
    assert.equal(res[1], donor1);
    assert.equal(res[2], 'Donor1');
    assert.equal(res[3], 86400);
  }).timeout(6000);
  it('Should make a donation', async () => {
    await liquidPledging.donate(1, 1, { from: donor1, value: utils.toWei(1) });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 1);
    await liquidPledging.getNote(1);
  }).timeout(6000);
  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 0, 0, { from: delegate1 });
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 2);
    const res = await liquidPledging.getNoteManager(2);
    assert.equal(res[0], 1); // Donor
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
  }).timeout(6000);
  it('Donor should delegate on the delegate', async () => {
    await liquidPledging.transfer(1, 1, utils.toWei(0.5), 2, { from: donor1 });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 2);
    const res1 = await liquidPledging.getNote(1);
    assert.equal(res1[0], utils.toWei(0.5));
    const res2 = await liquidPledging.getNote(2);
    assert.equal(res2[0], utils.toWei(0.5));
    assert.equal(res2[1], 1); // One delegate

    const d = await liquidPledging.getNoteDelegate(2, 1);
    assert.equal(d[0], 2);
    assert.equal(d[1], delegate1);
    assert.equal(d[2], 'Delegate1');
  }).timeout(6000);
  it('Should create a 2 projects', async () => {
    await liquidPledging.addProject('Project1', adminProject1, 0, 86400, 0, { from: adminProject1 });

    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 3);
    const res = await liquidPledging.getNoteManager(3);
    assert.equal(res[0], 2); // Project type
    assert.equal(res[1], adminProject1);
    assert.equal(res[2], 'Project1');
    assert.equal(res[3], 86400);
    assert.equal(res[4], 0);
    assert.equal(res[5], false);

    await liquidPledging.addProject('Project2', adminProject2, 0, 86400, 0, { from: adminProject2 });

    const nManagers2 = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers2, 4);
    const res4 = await liquidPledging.getNoteManager(4);
    assert.equal(res4[0], 2); // Project type
    assert.equal(res4[1], adminProject2);
    assert.equal(res4[2], 'Project2');
    assert.equal(res4[3], 86400);
    assert.equal(res4[4], 0);
    assert.equal(res4[5], false);
  }).timeout(6000);
  it('Delegate should assign to project1', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.transfer(2, 2, utils.toWei(0.2), 3, { from: delegate1 });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 3);
    const res3 = await liquidPledging.getNote(3);
    assert.equal(res3[0], utils.toWei(0.2));
    assert.equal(res3[1], 1); // Owner
    assert.equal(res3[2], 1); // Delegates
    assert.equal(res3[3], 3); // Proposed Project
    assert.isAbove(utils.toDecimal(res3[4]), n + 86000);
    assert.equal(res3[5], 0); // Old Node
    assert.equal(res3[6], 0); // Not Paid
  }).timeout(6000);
  it('Donor should change his mind and assign half of it to project2', async () => {
    await liquidPledging.transfer(1, 3, utils.toWei(0.1), 4, { from: donor1 });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 4);
    const res3 = await liquidPledging.getNote(3);
    assert.equal(res3[0], utils.toWei(0.1));
    const res4 = await liquidPledging.getNote(4);
    assert.equal(res4[1], 4); // Owner
    assert.equal(res4[2], 0); // Delegates
    assert.equal(res4[3], 0); // Proposed Project
    assert.equal(res4[4], 0);
    assert.equal(res4[5], 2); // Old Node
    assert.equal(res4[6], 0); // Not Paid
  }).timeout(6000);
  it('After the time, the project1 should be able to spend part of it', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + 86401);
    await liquidPledging.withdraw(3, utils.toWei(0.05), { from: adminProject1 });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 6);
    const res5 = await liquidPledging.getNote(5);
    assert.equal(res5[0], utils.toWei(0.05));
    assert.equal(res5[1], 3); // Owner
    assert.equal(res5[2], 0); // Delegates
    assert.equal(res5[3], 0); // Proposed Project
    assert.equal(res5[4], 0);            // commit time
    assert.equal(res5[5], 2); // Old Node
    assert.equal(res5[6], 0); // Not Paid
    const res6 = await liquidPledging.getNote(6);
    assert.equal(res6[0], utils.toWei(0.05));
    assert.equal(res6[1], 3); // Owner
    assert.equal(res6[2], 0); // Delegates
    assert.equal(res6[3], 0); // Proposed Project
    assert.equal(res6[4], 0);            // commit time
    assert.equal(res6[5], 2); // Old Node
    assert.equal(res6[6], 1); // Peinding paid Paid
  }).timeout(6000);
  it('Should collect the Ether', async () => {
    const initialBalance = await web3.eth.getBalance(adminProject1);

    await vault.confirmPayment(0);
    const finalBalance = await web3.eth.getBalance(adminProject1);

    const collected = utils.fromWei(utils.toBN(finalBalance).sub(utils.toBN(initialBalance)));

    assert.equal(collected, 0.05);

    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(nNotes, 7);
    const res7 = await liquidPledging.getNote(7);
    assert.equal(res7[0], utils.toWei(0.05));
    assert.equal(res7[1], 3); // Owner
    assert.equal(res7[2], 0); // Delegates
    assert.equal(res7[3], 0); // Proposed Project
    assert.equal(res7[4], 0);            // commit time
    assert.equal(res7[5], 2); // Old Node
    assert.equal(res7[6], 2); // Peinding paid Paid
  }).timeout(6000);
  it('Admin of the project1 should be able to cancel project1', async () => {
    await liquidPledging.cancelProject(3, { from: adminProject1 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.managers[3].canceled, true);
  }).timeout(6000);
  it('Should not allow to withdraw from a canceled project', async () => {
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(utils.fromWei(st.notes[5].amount), 0.05);
    await assertFail(async () => {
      await liquidPledging.withdraw(5, utils.toWei(0.01), { from: adminProject1 });
    });
  }).timeout(6000);
  it('Delegate should send part of this ETH to project2', async () => {
    await liquidPledging.transfer(2, 5, utils.toWei(0.03), 4, {
      $extraGas: 100000,
      from: delegate1,
    });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.notes.length, 9);
    assert.equal(utils.fromWei(st.notes[8].amount), 0.03);
    assert.equal(st.notes[8].owner, 1);
    assert.equal(st.notes[8].delegates.length, 1);
    assert.equal(st.notes[8].delegates[0].id, 2);
    assert.equal(st.notes[8].proposedProject, 4);
  }).timeout(6000);
  it('Donor should be able to send the remaining to project2', async () => {
    await liquidPledging.transfer(1, 5, utils.toWei(0.02), 4, { from: donor1, $extraGas: 100000 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.notes.length, 9);
    assert.equal(utils.fromWei(st.notes[5].amount), 0);
    assert.equal(utils.fromWei(st.notes[4].amount), 0.12);
  }).timeout(6000);
  it('A subproject 2a and a delegate2 is created', async () => {
    await liquidPledging.addProject('Project2a', adminProject2a, 4, 86400, 0, { from: adminProject2 });
    await liquidPledging.addDelegate('Delegate2', 0, 0, { from: delegate2 });
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(nManagers, 6);
  }).timeout(6000);
  it('Project 2 delegate in delegate2', async () => {
    await liquidPledging.transfer(4, 4, utils.toWei(0.02), 6, { from: adminProject2 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.notes.length, 10);
    assert.equal(utils.fromWei(st.notes[9].amount), 0.02);
    assert.equal(utils.fromWei(st.notes[4].amount), 0.1);
  }).timeout(6000);
  it('delegate2 assigns to projec2a', async () => {
    await liquidPledging.transfer(6, 9, utils.toWei(0.01), 5, { from: delegate2 });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.notes.length, 11);
    assert.equal(utils.fromWei(st.notes[9].amount), 0.01);
    assert.equal(utils.fromWei(st.notes[10].amount), 0.01);
  }).timeout(4000);
  it('project2a authorize to spend a litle', async () => {
    const n = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(n + (86401 * 3));
    await liquidPledging.withdraw(10, utils.toWei(0.005), { from: adminProject2a });
    const st = await liquidPledging.getState(liquidPledging);
    assert.equal(st.notes.length, 13);
    assert.equal(utils.fromWei(st.notes[10].amount), 0);
    assert.equal(utils.fromWei(st.notes[11].amount), 0.005);
    assert.equal(utils.fromWei(st.notes[12].amount), 0.005);
  }).timeout(4000);
  it('project2 is canceled', async () => {
    await liquidPledging.cancelProject(4, { from: adminProject2 });
  }).timeout(6000);
  it('project2 should not be able to confirm payment', async () => {
    await assertFail(async () => {
      await vault.confirmPayment(1);
    });
  }).timeout(6000);
  it('Should not be able to withdraw it', async () => {
    await assertFail(async () => {
      await liquidPledging.withdraw(12, utils.toWei(0.005), { from: donor1 });
    });
  }).timeout(6000);
  it('Should be able to cancel payment', async () => {
    // bug somewhere which will throw invalid op_code if we don't provide gas or extraGas
    await vault.cancelPayment(1, { $extraGas: 100000 });
    const st = await liquidPledging.getState();
    assert.equal(st.notes.length, 13);
    assert.equal(utils.fromWei(st.notes[2].amount), 0.31);
    assert.equal(utils.fromWei(st.notes[11].amount), 0);
    assert.equal(utils.fromWei(st.notes[12].amount), 0);
  }).timeout(6000);
  it('original owner should recover the remaining funds', async () => {
    await liquidPledging.withdraw(1, utils.toWei(0.5), { from: donor1 });
    await liquidPledging.withdraw(2, utils.toWei(0.31), { from: donor1 });
    await liquidPledging.withdraw(4, utils.toWei(0.1), { $extraGas: 100000, from: donor1 });

    await liquidPledging.withdraw(8, utils.toWei(0.03), { $extraGas: 100000, from: donor1 });
    await liquidPledging.withdraw(9, utils.toWei(0.01), { $extraGas: 100000, from: donor1 });

    const initialBalance = await web3.eth.getBalance(donor1);
    await vault.multiConfirm([2, 3, 4, 5, 6]);

    const finalBalance = await web3.eth.getBalance(donor1);
    const collected = utils.fromWei(utils.toBN(finalBalance).sub(utils.toBN(initialBalance)));

    assert.equal(collected, 0.95);
  }).timeout(10000);
  it('Should make a donation and create donor', async () => {
    const oldNNotes = await liquidPledging.numberOfNotes();
    const oldNManagers = await liquidPledging.numberOfNoteManagers();
    await liquidPledging.donate(0, 1, { from: donor2, value: utils.toWei(1) });
    const nNotes = await liquidPledging.numberOfNotes();
    assert.equal(utils.toDecimal(nNotes), utils.toDecimal(oldNNotes) + 1);
    const nManagers = await liquidPledging.numberOfNoteManagers();
    assert.equal(utils.toDecimal(nManagers), utils.toDecimal(oldNManagers) + 1);
    const res = await liquidPledging.getNoteManager(nManagers);
    assert.equal(res[0], 0); // Donor
    assert.equal(res[1], donor2);
    assert.equal(res[2], '');
    assert.equal(res[3], 259200); // default to 3 day commitTime
  }).timeout(6000);
});
