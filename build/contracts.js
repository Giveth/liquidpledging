const globby = require('globby');
const generateClass = require('eth-contract-class').default;

const contracts = {};
globby.sync('*.json', { cwd: __dirname }).forEach((file) => {
  const { contractName, compilerOutput } = require(`./${file}`);

  if (compilerOutput.abi && compilerOutput.evm.bytecode.object.length > 0) {
    contracts[contractName] = generateClass(
      compilerOutput.abi,
      `0x${compilerOutput.evm.bytecode.object}`,
    );
  }
});

module.exports = contracts;
