const VaultAbi = require("../build/Vault.sol").VaultAbi;
const VaultByteCode = require("../build/Vault.sol").VaultByteCode;
const runethtx = require("runethtx");

module.exports = runethtx.generateClass(VaultAbi, VaultByteCode);
