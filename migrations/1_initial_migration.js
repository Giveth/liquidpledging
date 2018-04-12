const Migrations = artifacts.require('./truffle/Migrations.sol')

module.exports = (deployer) => {
  deployer.deploy(Migrations)
}
