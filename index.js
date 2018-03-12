const contracts = require('./build/contracts');
exports.LiquidPledging = contracts.LiquidPledging;
exports.LiquidPledgingState = require('./lib/liquidPledgingState.js');
exports.LPVault = contracts.LPVault;
exports.LPFactory = contracts.LPFactory;
exports.test = {
    StandardTokenTest: contracts.StandardToken,
    assertFail: require('./test/helpers/assertFail')
};
