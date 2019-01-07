/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const chai = require('chai');
const { test } = require('../index');
const deployLP = require('./helpers/deployLP');

const compilerOutput = require('../dist/contracts/TestSimpleProjectPluginFactory.json');
const simpleProjectPluginFactoryAbi = compilerOutput.abiDefinition;
const simpleProjectPluginFactoryByteCode = compilerOutput.code;
const simpleProjectPluginRuntimeByteCode =
  '0x' + require('../dist/contracts/TestSimpleProjectPlugin.json').runtimeBytecode;
const assert = chai.assert;

const { assertFail } = test;

let accounts;

config({}, (err, theAccounts) => {
  accounts = theAccounts;
});

describe('LiquidPledging plugins test', function() {
  this.timeout(0);

  let liquidPledging;
  let vault;
  let giver1;
  let adminProject1;
  let adminDelegate1;

  before(async () => {
    adminProject1 = accounts[2];
    adminDelegate1 = accounts[3];

    const deployment = await deployLP(web3);
    giver1 = deployment.giver1;
    vault = deployment.vault;
    liquidPledging = deployment.liquidPledging;
    liquidPledgingState = deployment.liquidPledgingState;
  });

  it('Should create create giver with no plugin', async function() {
    await liquidPledging.addGiver('Giver1', '', 0, '0x0000000000000000000000000000000000000000', {
      from: adminProject1,
    });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 1);
  });

  it('Should fail to create giver with invalid plugin', async function() {
    await assertFail(
      liquidPledging.addGiver('Giver2', '', 0, vault.$address, { from: giver1, gas: 4000000 }),
    );
  });

  it('Should fail to create delegate with invalid plugin', async function() {
    await assertFail(
      liquidPledging.addDelegate('delegate1', '', 0, liquidPledging.$address, {
        from: adminDelegate1,
        gas: 4000000,
      }),
    );
  });

  it('Should fail to create project with invalid plugin', async function() {
    await assertFail(
      liquidPledging.addProject('Project1', '', giver1, 0, 0, vault.$address, {
        from: adminProject1,
        gas: 4000000,
      }),
    );
  });

  it('Should deploy TestSimpleProjectPlugin and add project', async function() {
    // add plugin as valid plugin
    const codeHash = web3.utils.soliditySha3(simpleProjectPluginRuntimeByteCode);
    await liquidPledging.addValidPluginContract(codeHash, { $extraGas: 200000 });

    // deploy new plugin
    const factoryContract = await new web3.eth.Contract(simpleProjectPluginFactoryAbi)
      .deploy({
        data: simpleProjectPluginFactoryByteCode,
        arguments: [],
      })
      .send({ from: adminProject1, gas: 5000000 });
    factoryContract.setProvider(web3.currentProvider);

    await factoryContract.methods
      .deploy(liquidPledging.$address, 'SimplePlugin1', '', 0)
      .send({ from: adminProject1, gas: 5000000 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should allow all plugins', async function() {
    await liquidPledging.useWhitelist(false, { $extraGas: 200000 });

    await liquidPledging.addGiver('Giver2', '', 0, vault.$address, { from: giver1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 3);
  });
});
