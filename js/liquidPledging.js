const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(LiquidPledgingAbi, LiquidPledgingCode);

