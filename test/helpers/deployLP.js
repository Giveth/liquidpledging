const LiquidPledgingState = require('../../js/liquidPledgingState');

const embarkConfig = (additionalContracts = {}) => {
  if (!embark) throw new Error('embarkConfig can only be within the Embark framework');
  const contracts = Object.assign(
    {
      RecoveryVault: {},
      LPVault: {},
      LiquidPledgingMock: {},
      Kernel: {
        args: {
          _shouldPetrify: 'false',
        },
      },
      ACL: {},
      DAOFactory: {
        args: ['$Kernel', '$ACL', '0x0000000000000000000000000000000000000000'],
      },
      LPFactory: {
        args: {
          _daoFactory: '$DAOFactory',
          _vaultBase: '$LPVault',
          _lpBase: '$LiquidPledgingMock',
        },
      },
      StandardToken: {},
    },
    additionalContracts,
  );

  config({ contracts }, (err, theAccounts) => {
    accounts = theAccounts;
  });
};

const deploy = async () => {
  if (!embark) throw new Error('deployLP can only be within the Embark framework');
  const RecoveryVault = embark.require('Embark/contracts/RecoveryVault');
  const lpFactory = embark.require('Embark/contracts/LPFactory');
  const LPVault = embark.require('Embark/contracts/LPVault');
  const LiquidPledgingMock = embark.require('Embark/contracts/LiquidPledgingMock');
  const StandardTokenTest = embark.require('Embark/contracts/StandardToken');
  const accounts = await web3.eth.getAccounts();
  const giver1 = accounts[1];

  const recoveryVault = RecoveryVault.$address;

  const r = await lpFactory.newLP(accounts[0], recoveryVault);

  const vaultAddress = r.events.DeployVault.returnValues.vault;
  vault = LPVault.at(vaultAddress);

  const lpAddress = r.events.DeployLiquidPledging.returnValues.liquidPledging;
  liquidPledging = LiquidPledgingMock.at(lpAddress);

  const liquidPledgingState = new LiquidPledgingState(liquidPledging);

  const token = StandardTokenTest;
  await token.mint(giver1, web3.utils.toWei('1000'));
  await token.approve(liquidPledging.$address, '0xFFFFFFFFFFFFFFFF', { from: giver1 });

  return {
    accounts,
    recoveryVault,
    liquidPledging,
    liquidPledgingState,
    vault,
    token,
    giver1,
  };
};

module.exports = { embarkConfig, deploy };
