const VaultAbi = require('../build/LPVault.sol').VaultAbi;
const VaultByteCode = require('../build/LPVault.sol').VaultByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(VaultAbi, VaultByteCode);
