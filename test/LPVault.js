/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const { assert } = require('chai');
const assertFail = require('./helpers/assertFail');
const { embarkConfig, deploy: deployLP } = require('./helpers/deployLP');

const Kernel = embark.require('Embark/contracts/Kernel');
const ACL = embark.require('Embark/contracts/ACL');

embarkConfig();

describe('LPVault test', function() {
  this.timeout(0);

  let accounts;
  let liquidPledging;
  let vault;
  let vaultOwner;
  let escapeHatchCaller;
  let recoveryVault;
  let giver1;
  let adminProject1;
  let restrictedPaymentsConfirmer;
  let token;

  before(async () => {
    accounts = await web3.eth.getAccounts();
    adminProject1 = accounts[2];
    vaultOwner = accounts[3];
    escapeHatchCaller = accounts[4];
    restrictedPaymentsConfirmer = accounts[5];
  });

  it('Should deploy LPVault contract', async function() {
    const deployment = await deployLP(web3);
    giver1 = deployment.giver1;
    vault = deployment.vault;
    liquidPledging = deployment.liquidPledging;
    liquidPledgingState = deployment.liquidPledgingState;
    token = deployment.token;
    recoveryVault = deployment.recoveryVault;
  });

  it('Should setup LPVault contract', async function() {
    // set permissions
    const kernel = Kernel.at(await liquidPledging.kernel());
    acl = ACL.at(await kernel.acl());
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

    await liquidPledging.addGiver('Giver1', '', 0, '0x0000000000000000000000000000000000000000', {
      from: giver1,
      $extraGas: 100000,
    });
    await liquidPledging.addProject(
      'Project1',
      '',
      adminProject1,
      0,
      0,
      '0x0000000000000000000000000000000000000000',
      {
        from: adminProject1,
        $extraGas: 100000,
      },
    );

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
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
