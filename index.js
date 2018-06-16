const LPFactoryArtifact = require('./build/LPFactory.json');
const LiquidPledgingArtifact = require('./build/LiquidPledging.json');
const LPVaultArtifact = require('./build/LPVault.json');
const KernelArtifact = require('./build/Kernel.json');
const ACLArtifact = require('./build/ACL.json');
const StandardTokenTestAtifact = require('./build/StandardToken.json');
const LiquidPledgingMockArtifact = require('./build/LiquidPledgingMock.json');
const generateClass = require('eth-contract-class').default;

module.exports = {
  LiquidPledging: generateClass(
    LiquidPledgingArtifact.compilerOutput.abi,
    `0x${LiquidPledgingArtifact.compilerOutput.evm.bytecode.object}`,
  ),
  LPFactory: generateClass(
    LPFactoryArtifact.compilerOutput.abi,
    `0x${LPFactoryArtifact.compilerOutput.evm.bytecode.object}`,
  ),
  LiquidPledgingState: require('./lib/liquidPledgingState.js'),
  LPVault: generateClass(
    LPVaultArtifact.compilerOutput.abi,
    `0x${LPVaultArtifact.compilerOutput.evm.bytecode.object}`,
  ),
  Kernel: generateClass(
    KernelArtifact.compilerOutput.abi,
    `0x${KernelArtifact.compilerOutput.evm.bytecode.object}`,
  ),
  ACL: generateClass(
    ACLArtifact.compilerOutput.abi,
    `0x${ACLArtifact.compilerOutput.evm.bytecode.object}`,
  ),
  test: {
    StandardTokenTest: generateClass(
    StandardTokenTestAtifact.compilerOutput.abi,
    `0x${StandardTokenTestAtifact.compilerOutput.evm.bytecode.object}`,
    ),
    assertFail: require('./test/helpers/assertFail'),
    LiquidPledgingMock: generateClass(
    LiquidPledgingMockArtifact.compilerOutput.abi,
    `0x${LiquidPledgingMockArtifact.compilerOutput.evm.bytecode.object}`,
    ),
  },
};
