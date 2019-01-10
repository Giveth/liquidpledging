'use strict';

var generateClass = require('eth-contract-class').default;

var LPFactoryArtifact = require('../build/LPFactory.json');
var LiquidPledgingArtifact = require('../build/LiquidPledging.json');
var LPVaultArtifact = require('../build/LPVault.json');
var KernelArtifact = require('../build/Kernel.json');
var ACLArtifact = require('../build/ACL.json');
var AppProxyUpgradeableArtifact = require('../build/AppProxyUpgradeable.json');
var StandardTokenTestAtifact = require('../build/StandardToken.json');
var LiquidPledgingMockArtifact = require('../build/LiquidPledgingMock.json');
var RecoveryVaultArtifact = require('../build/RecoveryVault.json');

module.exports = {
  LiquidPledging: generateClass(LiquidPledgingArtifact.compilerOutput.abi, LiquidPledgingArtifact.compilerOutput.evm.bytecode.object),
  LPFactory: generateClass(LPFactoryArtifact.compilerOutput.abi, LPFactoryArtifact.compilerOutput.evm.bytecode.object),
  LiquidPledgingState: require('../lib/liquidPledgingState.js'),
  LPVault: generateClass(LPVaultArtifact.compilerOutput.abi, LPVaultArtifact.compilerOutput.evm.bytecode.object),
  Kernel: generateClass(KernelArtifact.compilerOutput.abi, KernelArtifact.compilerOutput.evm.bytecode.object),
  ACL: generateClass(ACLArtifact.compilerOutput.abi, ACLArtifact.compilerOutput.evm.bytecode.object),
  AppProxyUpgradeable: generateClass(AppProxyUpgradeableArtifact.compilerOutput.abi, AppProxyUpgradeableArtifact.compilerOutput.evm.bytecode.object),
  test: {
    RecoveryVault: generateClass(RecoveryVaultArtifact.compilerOutput.abi, RecoveryVaultArtifact.compilerOutput.evm.bytecode.object),
    StandardTokenTest: generateClass(StandardTokenTestAtifact.compilerOutput.abi, StandardTokenTestAtifact.compilerOutput.evm.bytecode.object),
    LiquidPledgingMock: generateClass(LiquidPledgingMockArtifact.compilerOutput.abi, LiquidPledgingMockArtifact.compilerOutput.evm.bytecode.object)
  }
};