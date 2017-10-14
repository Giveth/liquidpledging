const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = generateClass(LiquidPledgingMockAbi, LiquidPledgingMockCode);
