/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const chai = require('chai');
const { embarkConfig, deploy: deployLP } = require('./helpers/deployLP');
const assertFail = require('./helpers/assertFail');

const TestSimpleProjectPlugin = embark.require('Embark/contracts/TestSimpleProjectPlugin');
const TestSimpleProjectPluginFactory = embark.require(
  'Embark/contracts/TestSimpleProjectPluginFactory',
);

const assert = chai.assert;

embarkConfig();

describe('LiquidPledging plugins test', function() {
  this.timeout(0);

  let accounts;
  let liquidPledging;
  let vault;
  let giver1;
  let adminProject1;
  let adminDelegate1;

  before(async () => {
    const deployment = await deployLP(web3);
    accounts = deployment.accounts;

    adminProject1 = accounts[2];
    adminDelegate1 = accounts[3];

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
    const codeHash = web3.utils.keccak256(TestSimpleProjectPlugin.$runtimeByteCode);
    await liquidPledging.addValidPluginContract(codeHash, { $extraGas: 200000 });

    // deploy new plugin
    const factoryContract = await TestSimpleProjectPluginFactory.new({ from: adminProject1 });

    await factoryContract.deploy(liquidPledging.$address, 'SimplePlugin1', '', 0, {
      from: adminProject1,
      gas: 5000000,
    });

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
