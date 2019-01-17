const contracts = require('./js/contracts');
const assertFail = require('./test/helpers/assertFail');
const { embarkConfig, deploy: deployLP } = require('./test/helpers/deployLP');

module.exports = {
  ...contracts,
  test: {
    assertFail,
    embarkConfig,
    deployLP,
  },
};
