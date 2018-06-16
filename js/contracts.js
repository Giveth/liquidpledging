const generateClass = require('eth-contract-class').default;

const LPFactoryArtifact = require('../build/LPFactory.json');
const LiquidPledgingArtifact = require('../build/LiquidPledging.json');
const LPVaultArtifact = require('../build/LPVault.json');
const KernelArtifact = require('../build/Kernel.json');
const ACLArtifact = require('../build/ACL.json');
const StandardTokenTestAtifact = require('../build/StandardToken.json');
const LiquidPledgingMockArtifact = require('../build/LiquidPledgingMock.json');
const RecoveryVaultArtifact = require('../build/RecoveryVault.json');

module.exports = {
  LiquidPledging: generateClass(
    LiquidPledgingArtifact.compilerOutput.abi,
    LiquidPledgingArtifact.compilerOutput.evm.bytecode.object,
  ),
  LPFactory: generateClass(
    LPFactoryArtifact.compilerOutput.abi,
    LPFactoryArtifact.compilerOutput.evm.bytecode.object,
  ),
  LiquidPledgingState: require('../lib/liquidPledgingState.js'),
  LPVault: generateClass(
    LPVaultArtifact.compilerOutput.abi,
    LPVaultArtifact.compilerOutput.evm.bytecode.object,
  ),
  Kernel: generateClass(
    KernelArtifact.compilerOutput.abi,
    KernelArtifact.compilerOutput.evm.bytecode.object,
  ),
  ACL: generateClass(
    ACLArtifact.compilerOutput.abi,
    ACLArtifact.compilerOutput.evm.bytecode.object,
  ),
  test: {
    RecoveryVault: generateClass(
      RecoveryVaultArtifact.compilerOutput.abi,
      RecoveryVaultArtifact.compilerOutput.evm.bytecode.object,
    ),
    StandardTokenTest: generateClass(
      StandardTokenTestAtifact.compilerOutput.abi,
      StandardTokenTestAtifact.compilerOutput.evm.bytecode.object,
    ),
    LiquidPledgingMock: generateClass(
      LiquidPledgingMockArtifact.compilerOutput.abi,
      LiquidPledgingMockArtifact.compilerOutput.evm.bytecode.object,
    ),
  },
};
