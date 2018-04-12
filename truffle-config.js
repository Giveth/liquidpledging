module.exports = {
    networks: {
      rpc: {
        network_id: 15,
        host: 'localhost',
        port: 8545,
        gas: 6700000,
      },
      coverage: {
        host: "localhost",
        network_id: "*",
        port: 8555,
        gas: 0xffffffffff,
        gasPrice: 0x01
      }
  },
  solc: {
    optimizer: {
      enabled: true,
      runs: 1
    }
  }
}
