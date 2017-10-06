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
  const st = await liquidPledging.getState();
  console.log(JSON.stringify(st, null, 2));
};

describe('LiquidPledging test', function() {
  this.timeout(0);
  let testrpc;
  let web3;
  let accounts;
  let liquidPledging;
  let vault;
  let giver1;
  let giver2;
  let delegate1;
  let adminProject1;
  let adminProject2;
  let adminProject2a;
  let delegate2;

  before(async () => {

    testrpc = TestRPC.server({
      ws: true,
      gasLimit: 5800000,
      total_accounts: 10,
    });

    testrpc.listen(8546, '127.0.0.1');

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    giver1 = accounts[ 1 ];
    delegate1 = accounts[ 2 ];
    adminProject1 = accounts[ 3 ];
    adminProject2 = accounts[ 4 ];
    adminProject2a = accounts[ 5 ];
    delegate2 = accounts[ 6 ];
    giver2 = accounts[ 7 ];
  });

  after((done) => {
    testrpc.close();
    done();
  });

  it('Should deploy LiquidPledgin contract', async () => {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { gas: 5800000 });
    await vault.setLiquidPledging(liquidPledging.$address);
  });

  it('Should create a delegate', async () => {
    await liquidPledging.addDelegate('Delegate1', 'URLDelegate1', 0, 0, { from: delegate1 });
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 1);
    const res = await liquidPledging.getPledgeAdmin(1);
    assert.equal(res[0], 1); // Giver
    assert.equal(res[1], delegate1);
    assert.equal(res[2], 'Delegate1');
    assert.equal(res[3], 'URLDelegate1');
    assert.equal(res[4], 0);
  }).timeout(6000);

  it('Should make a donation and create giver', async () => {
    await liquidPledging.donate(0, 1, { from: giver1, value: '1000', gas: 2000000 });
    const nPledges = await liquidPledging.numberOfPledges();
    assert.equal(nPledges, 2);
    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
    const res = await liquidPledging.getPledgeAdmin(nAdmins);
    assert.equal(res[0], 0); // Giver
    assert.equal(res[1], giver1);
    assert.equal(res[2], '');
    assert.equal(res[3], '');
    assert.equal(res[4], 259200); // default to 3 day commitTime
  });

  it('Should not append delegate on veto delegation', async function() {
    await liquidPledging.addProject('Project 1', 'url', adminProject1, 0, 0, 0);
    // propose the delegation
    await liquidPledging.transfer(1, 2, '1000', 3, { from: delegate1, gas: 400000 });
    // await liquidPledging.transfer(1, 2, '1000', 5, { from: giver1, gas: 400000 });

    const origPledge = await liquidPledging.getPledge(2);
    assert.equal(origPledge.amount, '0');

//    await printState(liquidPledging);
    // veto the delegation
    await liquidPledging.transfer(2, 3, '1000', 1, { from: giver1, gas: 400000 });

    const currentPledge = await liquidPledging.getPledge(2);

//    await printState(liquidPledging);

    assert.equal(currentPledge.amount, '1000');
    assert.equal(currentPledge.nDelegates, 1);
  });


})
