const generateClass = require('eth-contract-class').default;

const LPFactoryArtifact = require('./dist/contracts/LPFactory.json');
const LiquidPledgingArtifact = require('./dist/contracts/LiquidPledging.json');
const LPVaultArtifact = require('./dist/contracts/LPVault.json');
const KernelArtifact = require('./dist/contracts/Kernel.json');
const DAOFactoryArtifact = require('./dist/contracts/DAOFactory.json');
const ACLArtifact = require('./dist/contracts/ACL.json');
const AppProxyUpgradeableArtifact = require('./dist/contracts/AppProxyUpgradeable.json');
const StandardTokenTestAtifact = require('./dist/contracts/StandardToken.json');
const LiquidPledgingMockArtifact = require('./dist/contracts/LiquidPledgingMock.json');
const RecoveryVaultArtifact = require('./dist/contracts/RecoveryVault.json');
const assertFail = require('./test/helpers/assertFail');
const { embarkConfig, deploy: deployLP } = require('./test/helpers/deployLP');

module.exports = {
  LiquidPledging: generateClass(
    LiquidPledgingArtifact.abiDefinition,
    LiquidPledgingArtifact.code,
  ),
  LPFactory: generateClass(
    LPFactoryArtifact.abiDefinition,
    LPFactoryArtifact.code,
  ),
  LiquidPledgingState: require('./js/liquidPledgingState.js'),
  LPVault: generateClass(
    LPVaultArtifact.abiDefinition,
    LPVaultArtifact.code,
  ),
  DAOFactory: generateClass(
    DAOFactoryArtifact.abiDefinition,
    DAOFactoryArtifact.code,
  ),
  Kernel: generateClass(
    KernelArtifact.abiDefinition,
    KernelArtifact.code,
  ),
  ACL: generateClass(
    ACLArtifact.abiDefinition,
    ACLArtifact.code,
  ),
  AppProxyUpgradeable: generateClass(
    AppProxyUpgradeableArtifact.abiDefinition,
    AppProxyUpgradeableArtifact.code,
  ),
  test: {
    RecoveryVault: generateClass(
      RecoveryVaultArtifact.abiDefinition,
      RecoveryVaultArtifact.code,
    ),
    StandardTokenTest: generateClass(
      StandardTokenTestAtifact.abiDefinition,
      StandardTokenTestAtifact.code,
    ),
    LiquidPledgingMock: generateClass(
      LiquidPledgingMockArtifact.abiDefinition,
      LiquidPledgingMockArtifact.code,
    ),
    assertFail,
    embarkConfig,
    deployLP,
  },
};
