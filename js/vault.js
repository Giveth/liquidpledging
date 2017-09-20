const VaultAbi = require('../build/Vault.sol').VaultAbi;
const VaultByteCode = require('../build/Vault.sol').VaultByteCode;
const generateClass = require('./generateClass');

module.exports = generateClass(VaultAbi, VaultByteCode);
