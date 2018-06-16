const generateClass = require('eth-contract-class').default;

const contracts = require('./js/contracts');
contracts.test.assertFail = require('./test/helpers/assertFail');
contracts.test.deployLP = require('./test/helpers/deployLP');

module.exports = contracts;