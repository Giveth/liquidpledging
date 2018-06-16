/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const TestRPC = require('ganache-cli');
const Web3 = require('web3');
const { assert } = require('chai');
const { LPVault, LPFactory, LiquidPledgingState, Kernel, ACL, test } = require('../index');
const { RecoveryVault } = require('../build/contracts');

const { StandardTokenTest, assertFail, LiquidPledgingMock } = test;

describe('LPVault test', function() {
  this.timeout(0);

  let testrpc;
  let web3;
  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let vaultOwner;
  let escapeHatchCaller;
  let recoveryVault;
  let giver1;
  let adminProject1;
  let restrictedPaymentsConfirmer;
  let token;

  before(async () => {
    testrpc = TestRPC.server({
      gasLimit: 6700000,
      total_accounts: 10,
    });

    testrpc.listen(8545, '127.0.0.1');

    web3 = new Web3('http://localhost:8545');
    accounts = await web3.eth.getAccounts();
    giver1 = accounts[1];
    adminProject1 = accounts[2];
    vaultOwner = accounts[3];
    escapeHatchCaller = accounts[4];
    recoveryVault = (await RecoveryVault.new(web3)).$address;
    restrictedPaymentsConfirmer = accounts[5];
  });

  after(done => {
    testrpc.close();
    done();
  });

  it('Should deploy LPVault contract', async function() {
    const baseVault = await LPVault.new(web3);
    const baseLP = await LiquidPledgingMock.new(web3, {
      gas: 6700000,
    });
    lpFactory = await LPFactory.new(web3, baseVault.$address, baseLP.$address, { gas: 6700000 });

    const r = await lpFactory.newLP(accounts[0], recoveryVault);

    const vaultAddress = r.events.DeployVault.returnValues.vault;
    vault = new LPVault(web3, vaultAddress);

    const lpAddress = r.events.DeployLiquidPledging.returnValues.liquidPledging;
    liquidPledging = new LiquidPledgingMock(web3, lpAddress);

    liquidPledgingState = new LiquidPledgingState(liquidPledging);

    // set permissions
    const kernel = new Kernel(web3, await liquidPledging.kernel());
    acl = new ACL(web3, await kernel.acl());
    await acl.createPermission(
      accounts[0],
      vault.$address,
      await vault.CANCEL_PAYMENT_ROLE(),
      accounts[0],
      { $extraGas: 200000 },
    );
    await acl.createPermission(
      accounts[0],
      vault.$address,
      await vault.CONFIRM_PAYMENT_ROLE(),
      accounts[0],
      { $extraGas: 200000 },
    );
    await acl.grantPermission(
      escapeHatchCaller,
      vault.$address,
      await vault.ESCAPE_HATCH_CALLER_ROLE(),
      { $extraGas: 200000 },
    );

    await liquidPledging.addGiver('Giver1', '', 0, '0x0', { from: giver1, $extraGas: 100000 });
    await liquidPledging.addProject('Project1', '', adminProject1, 0, 0, '0x0', {
      from: adminProject1,
      $extraGas: 100000,
    });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);

    token = await StandardTokenTest.new(web3);
    await token.mint(giver1, web3.utils.toWei('1000'));
    await token.approve(liquidPledging.$address, '0xFFFFFFFFFFFFFFFF', { from: giver1 });
  });

  it('Should hold funds from liquidPledging', async function() {
    await liquidPledging.addGiverAndDonate(2, token.$address, 10000, {
      from: giver1,
      $extraGas: 100000,
    });

    const balance = await token.balanceOf(vault.$address);
    assert.equal(10000, balance);
  });

  it('should restrict confirm payment to payments under specified amount', async function() {
    await liquidPledging.withdraw(2, 300, { from: adminProject1, $extraGas: 200000 });
    await liquidPledging.withdraw(2, 700, { from: adminProject1, $extraGas: 200000 });

    // set permission for 2nd param (p.amount) <= 300
    await acl.grantPermissionP(
      restrictedPaymentsConfirmer,
      vault.$address,
      await vault.CONFIRM_PAYMENT_ROLE(),
      ['0x010600000000000000000000000000000000000000000000000000000000012c'],
      { $extraGas: 200000 },
    );

    await assertFail(vault.confirmPayment(1, { from: restrictedPaymentsConfirmer, gas: 4000000 }));
    await vault.confirmPayment(0, { from: restrictedPaymentsConfirmer, $extraGas: 200000 });
  });

  it('Only escapeHatchCaller role should be able to pull "escapeHatch"', async function() {
    const preVaultBalance = await token.balanceOf(vault.$address);

    // transferToVault is a bit confusing, but is the name of the function in aragonOs
    // this is the escapeHatch and will transfer all funds to the recoveryVault
    await assertFail(vault.transferToVault(token.$address, { from: vaultOwner, gas: 6700000 }));
    assert.equal(await token.balanceOf(vault.$address), preVaultBalance);

    await vault.transferToVault(token.$address, { from: escapeHatchCaller, $extraGas: 100000 });

    const vaultBalance = await token.balanceOf(vault.$address);
    assert.equal(0, vaultBalance);

    const recoveryVaultBalance = await token.balanceOf(recoveryVault);
    assert.equal(preVaultBalance, recoveryVaultBalance);
  });
});
