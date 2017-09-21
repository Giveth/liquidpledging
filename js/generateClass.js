const Web3PromiEvent = require('web3-core-promievent');

function checkWeb3(web3) {
  if (typeof web3.version !== 'string' || !web3.version.startsWith('1.')) {
    throw new Error('web3 version 1.x is required');
  }
}

const estimateGas = (web3, method, opts) => {
  if (opts.$noEstimateGas) return Promise.resolve(4700000);
  if (opts.$gas || opts.gas) return Promise.resolve(opts.$gas || opts.gas);

  return method.estimateGas(opts)
    // eslint-disable-next-line no-confusing-arrow
    .then(gas => opts.$extraGas ? gas + opts.$extraGas : Math.floor(gas * 1.1));
};

// if constant method, executes a call, otherwise, estimates gas and executes send
const execute = (web3, txObject, opts, cb) => {
  const { _method } = txObject;

  if (_method.constant) return txObject.call(opts);

  // we need to create a new PromiEvent here b/c estimateGas returns a regular promise
  // however on a 'send' we want to return a PromiEvent
  const defer = new Web3PromiEvent();
  const relayEvent = event => (...args) => defer.eventEmitter.emit(event, ...args);

  estimateGas(web3, txObject, opts)
    .then((gas) => {
      Object.assign(opts, { gas });
      return (cb) ? txObject.send(opts, cb) : txObject.send(opts)
        // relay all events to our promiEvent
        .on('transactionHash', relayEvent('transactionHash'))
        .on('confirmation', relayEvent('confirmation'))
        .on('receipt', relayEvent('receipt'))
        .on('error', relayEvent('error'));
    })
    .then(defer.resolve)
    .catch(defer.reject);

  return defer.eventEmitter;
};

const methodWrapper = (web3, method, ...args) => {
  let cb;
  let opts = {};

  if (typeof args[args.length - 1] === 'function') cb = args.pop();
  if (typeof args[args.length - 1] === 'object') opts = args.pop();

  const txObject = method(...args);

  return execute(web3, txObject, opts, cb);
};


module.exports = (abi, bytecode) => {
  const C = function C(web3, address) {
    checkWeb3(web3);

    this.$web3 = web3;
    this.$address = address;
    this.$contract = new web3.eth.Contract(abi, address);
    this.$abi = abi;
    this.$byteCode = bytecode;


    Object.keys(this.$contract.methods)
      .filter(key => !key.startsWith('0x'))
      .forEach((key) => {
        this[key] = (...args) => methodWrapper(web3, this.$contract.methods[key], ...args);
      });

        // set default from address
    web3.eth.getAccounts()
      .then((accounts) => {
        this.$contract.options.from = (accounts.length > 0) ? accounts[0] : undefined;
      });
  };

  C.new = function (web3, ...args) {
    let opts = {};
    if (args && args.length > 0 && typeof args[args.length - 1] === 'object') {
      opts = args.pop();
    }

    const deploy = new web3.eth.Contract(abi)
      .deploy({
        data: bytecode,
        arguments: args,
      });

    const getAccount = () => {
      if (opts.from) return Promise.resolve(opts.from);

      return web3.eth.getAccounts()
        // eslint-disable-next-line no-confusing-arrow
        .then(accounts => (accounts.length > 0) ? accounts[0] : undefined);
    };

    return getAccount()
      .then(account => Object.assign(opts, { from: account }))
      .then(() => execute(web3, deploy, opts))
      .then(contract => new C(web3, contract.options.address));
  };

  return C;
};
