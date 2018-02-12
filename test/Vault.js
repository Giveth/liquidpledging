/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require("ganache-cli");
const Web3 = require('web3');
const chai = require('chai');
const assertFail = require('./helpers/assertFail');
const contracts = require("../build/contracts.js");

const LiquidPledgingState = require('../index').LiquidPledgingState;
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
  let restrictedPaymentsConfirmer;

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
    restrictedPaymentsConfirmer = accounts[ 6 ];
  });

  after((done) => {
    testrpc.close();
    done();
  });

  it('Should deploy Vault contract', async function () {
    const baseVault = await contracts.LPVault.new(web3);
    const baseLP = await contracts.LiquidPledgingMock.new(web3);
    lpFactory = await contracts.LPFactory.new(web3, baseVault.$address, baseLP.$address);

    const r = await lpFactory.newLP(accounts[0], escapeHatchDestination);

    const vaultAddress = r.events.DeployVault.returnValues.vault;
    vault = new contracts.LPVault(web3, vaultAddress);

    const lpAddress = r.events.DeployLiquidPledging.returnValues.liquidPledging;
    liquidPledging = new contracts.LiquidPledgingMock(web3, lpAddress);

    liquidPledgingState = new LiquidPledgingState(liquidPledging);

    // set permissions
    const kernel = new contracts.Kernel(web3, await liquidPledging.kernel());
    acl = new contracts.ACL(web3, await kernel.acl());
    await acl.createPermission(accounts[0], vault.$address, await vault.CANCEL_PAYMENT_ROLE(), accounts[0], { $extraGas: 200000 });
    await acl.createPermission(accounts[0], vault.$address, await vault.CONFIRM_PAYMENT_ROLE(), accounts[0], { $extraGas: 200000 });
    await acl.grantPermission(escapeHatchCaller, vault.$address, await vault.ESCAPE_HATCH_CALLER_ROLE(), {$extraGas: 200000});
    await acl.revokePermission(accounts[0], vault.$address, await vault.ESCAPE_HATCH_CALLER_ROLE(), {$extraGas: 200000});

    await liquidPledging.addGiver('Giver1', '', 0, '0x0', { from: giver1, $extraGas: 100000 });
    await liquidPledging.addProject('Project1', '', adminProject1, 0, 0, '0x0', { from: adminProject1, $extraGas: 100000 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should hold funds from liquidPledging', async function () {
    await liquidPledging.donate(0, 2, { from: giver1, value: 10000, $extraGas: 100000 });

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

    await vault.escapeFunds(0x0, 1000, { from: escapeHatchCaller, $extraGas: 200000 });

    const vaultBalance = await web3.eth.getBalance(vault.$address);
    assert.equal(9000, vaultBalance);

    const expected = web3.utils.toBN(preBalance).add(web3.utils.toBN('1000')).toString();
    const postBalance = await web3.eth.getBalance(escapeHatchDestination);

    assert.equal(expected, postBalance);

    await web3.eth.sendTransaction({from: escapeHatchCaller, to: vault.$address, value: '1000', gas: 21000});
  });

  it('should restrict confirm payment to payments under specified amount', async function () {
    await liquidPledging.withdraw(2, 300, {from: adminProject1, $extraGas: 200000});
    await liquidPledging.withdraw(2, 700, {from: adminProject1, $extraGas: 200000});

    // set permission for 2nd param (p.amount) <= 300
    await acl.grantPermissionP(restrictedPaymentsConfirmer, vault.$address, await vault.CONFIRM_PAYMENT_ROLE(), ["0x010600000000000000000000000000000000000000000000000000000000012c"], {$extraGas: 200000});

    assertFail(vault.confirmPayment(1, { from: restrictedPaymentsConfirmer, gas: 4000000 }));
    await vault.confirmPayment(0, { from: restrictedPaymentsConfirmer, $extraGas: 200000 });
  });
});

