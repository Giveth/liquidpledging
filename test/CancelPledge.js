/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require('ethereumjs-testrpc');
const Web3 = require('web3');
const chai = require('chai');
const liquidpledging = require('../index.js');
const assertFail = require('./helpers/assertFail');

const LiquidPledging = liquidpledging.LiquidPledgingMock;
const LiquidPledgingState = liquidpledging.LiquidPledgingState;
const Vault = liquidpledging.LPVault;
const assert = chai.assert;

const printState = async (liquidPledgingState) => {
  const st = await liquidPledgingState.getState();
  console.log(JSON.stringify(st, null, 2));
};

describe('LiquidPledging cancelPledge normal scenario', function () {
  this.timeout(0);

  let testrpc;
  let web3;
  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let giver1;
  let adminProject1;
  let adminProject2;

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
    adminProject1 = accounts[ 2 ];
    adminProject2 = accounts[ 3 ];
  });

  after((done) => {
    testrpc.close();
    done();
  });

  it('Should deploy LiquidPledging contract', async () => {
    vault = await Vault.new(web3, accounts[0], accounts[1]);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, accounts[0], accounts[1], { gas: 5800000 });
    await vault.setLiquidPledging(liquidPledging.$address);
    liquidPledgingState = new LiquidPledgingState(liquidPledging);
  });

  it('Should add project and donate ', async () => {
    await liquidPledging.addProject('Project1', 'URLProject1', adminProject1, 0, 0, '0x0', { from: adminProject1 });
    await liquidPledging.donate(0, 1, { from: giver1, value: '1000', gas: 500000 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should only allow pledge owner to cancel pledge', async () => {
    await assertFail(async () => {
      await liquidPledging.cancelPledge(2, 1000, { from: giver1, gas: 500000 });
    });
  });

  it('Should cancel pledge and return to oldPledge', async () => {
    await liquidPledging.cancelPledge(2, 1000, { from: adminProject1, gas: 500000 });

    const st = await liquidPledgingState.getState();

    assert.equal(st.pledges[1].amount, 1000);
    assert.equal(st.pledges[2].amount, 0);
  });

  it('Should not allow to cancel pledge if oldPledge === 0', async () => {
    await assertFail(async () => {
      await liquidPledging.cancelPledge(1, 1000, { from: giver1, gas: 500000 });
    });
  })
});

