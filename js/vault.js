const VaultAbi = require('../build/Vault.sol').VaultAbi;
const VaultByteCode = require('../build/Vault.sol').VaultByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(VaultAbi, VaultByteCode);
