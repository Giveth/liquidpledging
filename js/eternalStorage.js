const EternalStorageAbi = require('../build/EternalStorage.sol').EternalStorageAbi;
const EternalStorageCode = require('../build/EternalStorage.sol').EternalStorageByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(EternalStorageAbi, EternalStorageCode);

