/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const Ganache = require('ganache-cli');
const Web3 = require('web3');
const { assert } = require('chai');
const { test } = require('../index');
const deployLP = require('./helpers/deployLP');

const { assertFail } = test;

const printState = async liquidPledgingState => {
  const st = await liquidPledgingState.getState();
  console.log(JSON.stringify(st, null, 2));
};

describe('LiquidPledging cancelPledge normal scenario', function() {
  this.timeout(0);

  let ganache;
  let web3;
  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let vault;
  let giver1;
  let adminProject1;
  let adminProject2;
  let token;

  before(async () => {
    ganache = Ganache.server({
      gasLimit: 6700000,
      total_accounts: 10,
    });

    ganache.listen(8545, '127.0.0.1');

    web3 = new Web3('http://localhost:8545');
    accounts = await web3.eth.getAccounts();
    adminProject1 = accounts[2];
    adminProject2 = accounts[3];

    const deployment = await deployLP(web3);
    giver1 = deployment.giver1;
    vault = deployment.vault;
    liquidPledging = deployment.liquidPledging;
    liquidPledgingState = deployment.liquidPledgingState;
    token = deployment.token;
  });

  after(done => {
    ganache.close();
    done();
  });

  it('Should add project and donate ', async () => {
    await liquidPledging.addProject('Project1', 'URLProject1', adminProject1, 0, 0, '0x0', {
      from: adminProject1,
    });
    await liquidPledging.addGiverAndDonate(1, token.$address, 1000, { from: giver1 });

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 2);
  });

  it('Should only allow pledge owner to cancel pledge', async () => {
    await assertFail(liquidPledging.cancelPledge(2, 1000, { from: giver1, gas: 4000000 }));
  });

  it('Should cancel pledge and return to oldPledge', async () => {
    await liquidPledging.cancelPledge(2, 1000, { from: adminProject1, $extraGas: 200000 });

    const st = await liquidPledgingState.getState();

    assert.equal(st.pledges[1].amount, 1000);
    assert.equal(st.pledges[2].amount, 0);
  });

  it('Should not allow to cancel pledge if oldPledge === 0', async () => {
    await assertFail(liquidPledging.cancelPledge(1, 1000, { from: giver1, gas: 4000000 }));
  });
});
