/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require('ethereumjs-testrpc');
const Web3 = require('web3');
const chai = require('chai');
const liquidpledging = require('../index.js');
const assertFail = require('./helpers/assertFail');

const LiquidPledging = liquidpledging.LiquidPledgingMock;
const LiquidPledgingState = liquidpledging.LiquidPledgingState;
const simpleProjectPluginFactoryAbi = require('../build/TestSimpleProjectPluginFactory.sol').TestSimpleProjectPluginFactoryAbi;
const simpleProjectPluginFactoryByteCode = require('../build/TestSimpleProjectPluginFactory.sol').TestSimpleProjectPluginFactoryByteCode;
const simpleProjectPluginRuntimeByteCode = require('../build/TestSimpleProjectPluginFactory.sol').TestSimpleProjectPluginRuntimeByteCode;
const Vault = liquidpledging.LPVault;
const assert = chai.assert;

const printState = async (liquidPledgingState) => {
  const st = await liquidPledgingState.getState();
  console.log(JSON.stringify(st, null, 2));
};

describe('LiquidPledging plugins test', function () {
  this.timeout(0);

  let testrpc;
  let web3;
  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let giver1;
  let adminProject1;
  let adminDelegate1;

  before(async () => {
    testrpc = TestRPC.server({
      ws: true,
      gasLimit: 6500000,
      total_accounts: 10,
    });

    testrpc.listen(8546, '127.0.0.1');

    web3 = new Web3('ws://localhost:8546');
    accounts = await web3.eth.getAccounts();
    giver1 = accounts[ 1 ];
    adminProject1 = accounts[ 2 ];
    adminDelegate1 = accounts[ 3 ];
  });

  after((done) => {
    testrpc.close();
    done();
  });

  it('Should deploy LiquidPledging contract', async function() {
    vault = await Vault.new(web3);
    liquidPledging = await LiquidPledging.new(web3, vault.$address, { gas: 6500000 });
    await vault.setLiquidPledging(liquidPledging.$address);
    liquidPledgingState = new LiquidPledgingState(liquidPledging);
  });

  it('Should create create giver with no plugin', async function() {
    await liquidPledging.addGiver('Giver1', '', 0, '0x0', { from: adminProject1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 1);
  });

  it('Should fail to create giver with invalid plugin', async function() {
    await assertFail(async () => {
      await liquidPledging.addGiver('Giver2', '', 0, vault.$address, { from: giver1 });
    });
  });

  it('Should fail to create delegate with invalid plugin', async function() {
    await assertFail(async () => {
      await liquidPledging.addDelegate('delegate1', '', 0, liquidPledging.$address, { from: adminDelegate1});
    });
  });

  it('Should fail to create project with invalid plugin', async function() {
    await assertFail(async () => {
      await liquidPledging.addProject('Project1', '', giver1, 0, 0, vault.$address, { from: adminProject1});
    });
  });

  it('Should deploy TestSimpleProjectPlugin and add project', async function() {
    // add plugin as valid plugin
    const codeHash = web3.utils.soliditySha3(simpleProjectPluginRuntimeByteCode);
    await liquidPledging.addValidPlugin(codeHash);

    // deploy new plugin
    const factoryContract = await new web3.eth.Contract(simpleProjectPluginFactoryAbi)
      .deploy({
        data: simpleProjectPluginFactoryByteCode,
        arguments: []
      }).send({ from: adminProject1, gas: 5000000 });

    await factoryContract.methods
      .deploy(liquidPledging.$address, "SimplePlugin1", "", 0)
      .send({ from: adminProject1, gas: 4000000 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should allow all plugins', async function() {
    await liquidPledging.useWhitelist(false, { gas: 100000 });

    await liquidPledging.addGiver('Giver2', '', 0, vault.$address, { from: giver1, gas: 200000 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 3);
  });
});

