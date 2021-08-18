const generateClass = require('@giveth/eth-contract-class').default;

const contracts = require('./lib/contracts');
contracts.test.assertFail = require('./test/helpers/assertFail');
contracts.test.deployLP = require('./test/helpers/deployLP');

module.exports = contracts;
