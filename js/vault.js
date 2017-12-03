const LPVaultAbi = require('../build/LPVault.sol').LPVaultAbi;
const LPVaultByteCode = require('../build/LPVault.sol').LPVaultByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(LPVaultAbi, LPVaultByteCode);