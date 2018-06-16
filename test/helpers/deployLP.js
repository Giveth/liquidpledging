const { LPVault, LPFactory, LiquidPledgingState, Kernel, ACL, test } = require('../../index');
const { RecoveryVault } = require('../../build/contracts');

module.exports = async web3 => {
  const accounts = await web3.eth.getAccounts();
  const giver1 = accounts[1];

  const baseVault = await LPVault.new(web3);
  const baseLP = await test.LiquidPledgingMock.new(web3, {
    gas: 6700000,
  });
  const lpFactory = await LPFactory.new(web3, baseVault.$address, baseLP.$address, {
    gas: 6700000,
  });

  const recoveryVault = (await RecoveryVault.new(web3)).$address;
  const r = await lpFactory.newLP(accounts[0], recoveryVault);

  const vaultAddress = r.events.DeployVault.returnValues.vault;
  const vault = new LPVault(web3, vaultAddress);

  const lpAddress = r.events.DeployLiquidPledging.returnValues.liquidPledging;
  const liquidPledging = new test.LiquidPledgingMock(web3, lpAddress);

  const liquidPledgingState = new LiquidPledgingState(liquidPledging);

  const token = await test.StandardTokenTest.new(web3);
  await token.mint(giver1, web3.utils.toWei('1000'));
  await token.approve(liquidPledging.$address, '0xFFFFFFFFFFFFFFFF', { from: giver1 });

  return {
    liquidPledging,
    liquidPledgingState,
    vault,
    token,
    giver1,
  };
};
