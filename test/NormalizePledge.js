/* eslint-env mocha */
/* eslint-disable no-await-in-loop */
const { assert } = require('chai');
const { embarkConfig, deploy: deployLP } = require('./helpers/deployLP');

const printState = async liquidPledgingState => {
  const st = await liquidPledgingState.getState();
  console.log(JSON.stringify(st, null, 2));
};

embarkConfig();

describe('NormalizePledge test', function() {
  this.timeout(0);

  let accounts;
  let liquidPledging;
  let liquidPledgingState;
  let giver1;
  let giver2;
  let delegate1;
  let delegate2;
  let adminProject1;
  let adminProject2;
  let token;

  before(async () => {
    const deployment = await deployLP();
    accounts = deployment.accounts;
    
    delegate1 = accounts[2];
    delegate2 = accounts[3];
    adminProject1 = accounts[4];
    adminProject2 = accounts[5];
    giver2 = accounts[6];

    giver1 = deployment.giver1;
    liquidPledging = deployment.liquidPledging;
    liquidPledgingState = deployment.liquidPledgingState;
    token = deployment.token;

    await token.mint(giver2, web3.utils.toWei('1000'));
    await token.approve(liquidPledging.$address, '0xFFFFFFFFFFFFFFFF', { from: giver2 });
  });

  it('Should add pledgeAdmins', async () => {
    await liquidPledging.addGiver('Giver1', 'URLGiver1', 86400, '0x0000000000000000000000000000000000000000', { from: giver1 }); // pledgeAdmin 1
    await liquidPledging.addDelegate('Delegate1', 'URLDelegate1', 259200, '0x0000000000000000000000000000000000000000', { from: delegate1 }); // pledgeAdmin 2
    await liquidPledging.addDelegate('Delegate2', 'URLDelegate2', 0, '0x0000000000000000000000000000000000000000', { from: delegate2 }); // pledgeAdmin 3
    await liquidPledging.addProject('Project1', 'URLProject1', adminProject1, 0, 0, '0x0000000000000000000000000000000000000000', {
      from: adminProject1,
    }); // pledgeAdmin 4
    await liquidPledging.addProject('Project2', 'URLProject2', adminProject2, 0, 0, '0x0000000000000000000000000000000000000000', {
      from: adminProject2,
    }); // pledgeAdmin 5
    await liquidPledging.addGiver('Giver2', 'URLGiver2', 0, '0x0000000000000000000000000000000000000000', { from: giver2 }); // pledgeAdmin 6

    const nAdmins = await liquidPledging.numberOfPledgeAdmins();
    assert.equal(nAdmins, 6);
  });

  it('Should commit pledges if commitTime has passed', async () => {
    // commitTime 259200
    await liquidPledging.donate(1, 2, token.$address, 1000, { from: giver1 });
    // commitTime 86400
    await liquidPledging.donate(1, 3, token.$address, 1000, { from: giver1 });
    // commitTime 0
    await liquidPledging.donate(6, 3, token.$address, 1000, { from: giver2 });

    // set the time
    const now = Math.floor(new Date().getTime() / 1000);
    await liquidPledging.setMockedTime(now, { $extraGas: 200000 });

    // delegate to project
    await liquidPledging.transfer(2, 2, 1000, 4, { from: delegate1 });
    await liquidPledging.transfer(3, 3, 1000, 4, { from: delegate2 });
    await liquidPledging.transfer(3, 5, 1000, 4, { from: delegate2 });

    // advance the time
    await liquidPledging.setMockedTime(now + 100000, { $extraGas: 200000 });

    await liquidPledging.mNormalizePledge([6, 7, 8], { $extraGas: 200000 });

    const st = await liquidPledgingState.getState();
    assert.equal(st.pledges.length, 11);
    assert.equal(st.pledges[6].amount, 1000);
    assert.equal(st.pledges[9].amount, 1000);
    assert.equal(st.pledges[9].owner, 4);
    assert.equal(st.pledges[9].oldPledge, 3);
    assert.equal(st.pledges[10].amount, 1000);
    assert.equal(st.pledges[10].owner, 4);
    assert.equal(st.pledges[10].oldPledge, 5);
  });

  it('Should transfer pledge to oldestPledgeNotCanceled', async () => {
    await liquidPledging.transfer(4, 10, 1000, 5, { from: adminProject1, $extraGas: 200000 });

    // cancel projects
    await liquidPledging.cancelProject(4, { from: adminProject1, $extraGas: 200000 });
    await liquidPledging.cancelProject(5, { from: adminProject2, $extraGas: 200000 });

    await liquidPledging.mNormalizePledge([9, 11], { $extraGas: 200000 });

    const st = await liquidPledgingState.getState();
    assert.equal(st.pledges.length, 12);
    assert.equal(st.pledges[3].amount, 1000);
    assert.equal(st.pledges[5].amount, 1000);
    assert.equal(st.pledges[9].amount, 0);
    assert.equal(st.pledges[11].amount, 0);
  });
});
