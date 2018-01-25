/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require("ganache-cli");
const Web3 = require('web3');
const chai = require('chai');
const liquidpledging = require('../index.js');
const EternalStorage = require('../js/eternalStorage');
const PledgeAdmins = require('../js/pledgeAdmins');
const assertFail = require('./helpers/assertFail');

const LiquidPledging = liquidpledging.LiquidPledgingMock;
const LiquidPledgingState = liquidpledging.LiquidPledgingState;
const LPVault = liquidpledging.LPVault;
const assert = chai.assert;

describe('Vault test', function () {
  this.timeout(0);

  let testrpc;
  let web3;
  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let vaultOwner;
  let escapeHatchCaller;
  let escapeHatchDestination;
  let giver1;
  let adminProject1;

  before(async () => {
    testrpc = TestRPC.server({
      ws: true,
      gasLimit: 6700000,
      total_accounts: 10,
    });

    testrpc.listen(8546, '127.0.0.1');

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    giver1 = accounts[ 1 ];
    adminProject1 = accounts[ 2 ];
    vaultOwner = accounts[ 3 ];
    escapeHatchDestination = accounts[ 4 ];
    escapeHatchCaller = accounts[ 5 ];
  });

  after((done) => {
    testrpc.close();
    done();
  });

  it('Should deploy Vault contract', async function () {
    vault = await LPVault.new(web3, escapeHatchCaller, escapeHatchDestination, {from: vaultOwner});
    const storage = await EternalStorage.new(web3, accounts[0], accounts[1]);

    liquidPledging = await LiquidPledging.new(web3, storage.$address, vault.$address, accounts[0], accounts[0], {gas: 6700000})

    await storage.changeOwnership(liquidPledging.$address);
    await vault.setLiquidPledging(liquidPledging.$address, {from: vaultOwner});

    liquidPledgingState = new LiquidPledgingState(liquidPledging);

    await liquidPledging.addGiver('Giver1', '', 0, '0x0', { from: giver1 });
    await liquidPledging.addProject('Project1', '', adminProject1, 0, 0, '0x0', { from: adminProject1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should hold funds from liquidPledging', async function () {
    await liquidPledging.donate(0, 2, { from: giver1, value: 10000 });

    const balance = await web3.eth.getBalance(vault.$address);
    assert.equal(10000, balance);
  });

  it('escapeFunds should fail', async function () {
    // only vaultOwner can escapeFunds
    await assertFail(vault.escapeFunds(0x0, 1000, {gas: 4000000}));

    // can't send more then the balance
    await assertFail(vault.escapeFunds(0x0, 11000, { from: vaultOwner, gas: 4000000 }));
  });

  it('escapeFunds should send funds to escapeHatchDestination', async function () {
    const preBalance = await web3.eth.getBalance(escapeHatchDestination);

    await vault.escapeFunds(0x0, 1000, { from: vaultOwner });

    const vaultBalance = await web3.eth.getBalance(vault.$address);
    assert.equal(9000, vaultBalance);

    const expected = web3.utils.toBN(preBalance).add(web3.utils.toBN('1000')).toString();
    const postBalance = await web3.eth.getBalance(escapeHatchDestination);

    assert.equal(expected, postBalance);
  });
});

