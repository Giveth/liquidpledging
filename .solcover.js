// NOTE: Upgrading to solidity-coverage 0.4.x breaks our tests

const truffleFiles = require('glob').sync(' ./contracts/truffle/*.sol')
const testFiles = require('glob').sync(' ./contracts/test/*.sol')
const skipFiles = truffleFiles.concat(testFiles).map(n => n.replace('./contracts/', ''))

console.log("skipFiles",skipFiles)

module.exports = {
    norpc: true,
    compileCommand: '../node_modules/.bin/truffle compile',
    testCommand: 'node --max-old-space-size=4096 ../node_modules/.bin/truffle test --network coverage',
    skipFiles: skipFiles,
    copyNodeModules: true,
}
