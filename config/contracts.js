module.exports = {
  // default applies to all environments
  default: {
    // Blockchain node to deploy the contracts
    deployment: {
      host: 'localhost', // Host of the blockchain node
      port: 8546, // Port of the blockchain node
      type: 'ws', // Type of connection (ws or rpc),
      // Accounts to use instead of the default account to populate your wallet
      /*,accounts: [
        {
          privateKey: "your_private_key",
          balance: "5 ether"  // You can set the balance of the account in the dev environment
                              // Balances are in Wei, but you can specify the unit with its name
        },
        {
          privateKeyFile: "path/to/file", // Either a keystore or a list of keys, separated by , or ;
          password: "passwordForTheKeystore" // Needed to decrypt the keystore file
        },
        {
          mnemonic: "12 word mnemonic",
          addressIndex: "0", // Optionnal. The index to start getting the address
          numAddresses: "1", // Optionnal. The number of addresses to get
          hdpath: "m/44'/60'/0'/0/" // Optionnal. HD derivation path
        }
      ]*/
    },
    // order of connections the dapp should connect to
    dappConnection: [
      '$WEB3', // uses pre existing web3 object if available (e.g in Mist)
      'ws://localhost:8546',
      'http://localhost:8545',
    ],

    gas: 'auto',

    // Strategy for the deployment of the contracts:
    // - implicit will try to deploy all the contracts located inside the contracts directory
    //            or the directory configured for the location of the contracts. This is default one
    //            when not specified
    // - explicit will only attempt to deploy the contracts that are explicity specified inside the
    //            contracts section.
    strategy: 'explicit',

    contracts: {},
  },

  // default environment, merges with the settings in default
  // assumed to be the intended environment by `embark run`
  development: {
    dappConnection: [
      'ws://localhost:8546',
      'http://localhost:8545',
      '$WEB3', // uses pre existing web3 object if available (e.g in Mist)
    ],
    contracts: {
      RecoveryVault: {},
      LPVault: {},
      LiquidPledgingMock: {},
      Kernel: {
        args: {
          _shouldPetrify: 'false',
        },
      },
      ACL: {},
      DAOFactory: {
        args: ['$Kernel', '$ACL', '0x0000000000000000000000000000000000000000'],
      },
      LPFactory: {
        args: {
          _daoFactory: '$DAOFactory',
          _vaultBase: '$LPVault',
          _lpBase: '$LiquidPledgingMock',
        },
      },

      // contracts for testing
      StandardToken: {},
    },

    // afterDeploy: [
    //   `console.log('we deployed here')`,
    //   `embark.logger.info('we deployed here')`,
    //   `LPFactory.methods.newLP("$accounts[0]", "$RecoveryVault").send({ gas: 7000000 })
    //     .then(({ events }) => { 
    //       console.log('method ran');
    //       global.LiquidPledging = new web3.eth.Contract(LiquidPledgingMockAbi, events.DeployLiquidPledging.returnValues.liquidPledging);
    //       global.LPVault = new web3.eth.Contract(LPVaultAbi, events.DeployVault.returnValues.vault);
    //       StandardToken.methods.mint(accounts[1], web3.utils.toWei('1000')).send();
    //       StandardToken.methods.approve(global.LiquidPledging.address, '0xFFFFFFFFFFFFFFFF').send({ from: "$accounts[1]" });
    //   })`
      // .catch(err => console.log('error', err))
      // `,
    // `web3.eth.getAccounts().then(accounts => {
    //   return LPFactory.methods.newLP(accounts[0], "$RecoveryVault").send({ gas: 7000000 })
    //     .then(({ events }) => { 
    //       global.LiquidPledging = new web3.eth.Contract(LiquidPledgingMockAbi, events.DeployLiquidPledging.returnValues.liquidPledging);
    //       global.LPVault = new web3.eth.Contract(LPVaultAbi, events.DeployVault.returnValues.vault);
    //       StandardToken.methods.mint(accounts[1], web3.utils.toWei('1000')).send();
    //       StandardToken.methods.approve(global.LiquidPledging.address, '0xFFFFFFFFFFFFFFFF').send({ from: accounts[1] });
    //     });
    // })
    // .catch(err => console.log('error', err))
    // `,
    // ],
  },

  // merges with the settings in default
  // used with "embark run privatenet"
  privatenet: {},

  // merges with the settings in default
  // used with "embark run testnet"
  testnet: {},

  // merges with the settings in default
  // used with "embark run livenet"
  livenet: {},

  // you can name an environment with specific settings and then specify with
  // "embark run custom_name" or "embark blockchain custom_name"
  //custom_name: {
  //}
};
