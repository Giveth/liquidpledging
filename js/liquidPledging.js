/* eslint-disable no-await-in-loop */
const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
const runethtx = require('runethtx');


module.exports = (test) => {
  const LiquidPledgingContract = test ?
  runethtx.generateClass(LiquidPledgingMockAbi, LiquidPledgingMockCode) :
  runethtx.generateClass(LiquidPledgingAbi, LiquidPledgingCode);

  return class LiquidPledging extends LiquidPledgingContract {
    constructor(web3, address) {
      super(web3, address);
      this.pledges = [];
      this.managers = [];
      this.b = 'xxxxxxx b xxxxxxxx';
    }

    async $getPledge(idPledge) {
      const pledge = {
        delegates: [],
      };
      const res = await this.getPledge(idPledge);
      pledge.amount = res[0];
      pledge.owner = res[1];
      for (let i = 1; i <= res[2].toNumber(); i += 1) {
        const delegate = {};
        const resd = await this.getPledgeDelegate(idPledge, i);
        delegate.id = resd[0].toNumber();
        delegate.addr = resd[1];
        delegate.name = resd[2];
        pledge.delegates.push(delegate);
      }
      if (res[3].toNumber()) {
        pledge.proposedCampaign = res[3].toNumber();
        pledge.commmitTime = res[4].toNumber();
      }
      if (res[5].toNumber()) {
        pledge.oldCampaign = res[5].toNumber();
      }
      if (res[6].toNumber() === 0) {
        pledge.paymentState = 'NotPaid';
      } else if (res[6].toNumber() === 1) {
        pledge.paymentState = 'Paying';
      } else if (res[6].toNumber() === 2) {
        pledge.paymentState = 'Paid';
      } else {
        pledge.paymentState = 'Unknown';
      }
      return pledge;
    }

    async $getManager(idManager) {
      const manager = {};
      const res = await this.getPledgeManager(idManager);
      if (res[0].toNumber() === 0) {
        manager.paymentState = 'Giver';
      } else if (res[0].toNumber() === 1) {
        manager.paymentState = 'Delegate';
      } else if (res[0].toNumber() === 2) {
        manager.paymentState = 'Campaign';
      } else {
        manager.paymentState = 'Unknown';
      }
      manager.addr = res[1];
      manager.name = res[2];
      manager.commitTime = res[3].toNumber();
      if (manager.paymentState === 'Campaign') {
        manager.parentCampaign = res[4];
        manager.canceled = res[5];
      }
      return manager;
    }

    async getState() {
      const st = {
        pledges: [null],
        managers: [null],
      };
      const nPledges = await this.numberOfPledges();
      for (let i = 1; i <= nPledges; i += 1) {
        const pledge = await this.$getPledge(i);
        st.pledges.push(pledge);
      }

      const nManagers = await this.numberOfPledgeManagers();
      for (let i = 1; i <= nManagers; i += 1) {
        const manager = await this.$getManager(i);
        st.managers.push(manager);
      }
      return st;
    }

    generateGiversState() {
      const giversState = [];

      const getGiver = (idPledge) => {
        let pledge = this.pledges[idPledge];
        while (pledge.oldNode) pledge = this.pledges[idPledge];
        return pledge.owner;
      };

      // Add a giver structure to the list
      const addGiver = (_list, idGiver) => {
        const list = _list;
        if (!list[idGiver]) {
          list[idGiver] = {
            idGiver,
            notAssigned: {
              pledges: [],
              delegates: [],
            },
            precommitedCampaigns: [],
            commitedCampaigns: [],
          };
        }
      };

      // Add a delegate structure to the list
      const addDelegate = (_list, idDelegate) => {
        const list = _list;
        if (!list[idDelegate]) {
          list[idDelegate] = {
            idDelegate,
            name: this.managers[idDelegate].name,
            pledges: [],
            delegtes: [],
          };
        }
      };

      const addCampaign = (_list, idCampaign) => {
        const list = _list;
        if (!list[idCampaign]) {
          list[idCampaign] = {
            idCampaign,
            pledges: [],
            commitedCampaigns: [],
            name: this.managers[idCampaign].name,
            commitTime: this.managers[idCampaign].commitTime,
            owner: this.managers[idCampaign].owner,
            parentCampaign: this.managers[idCampaign].parentCampaign,
          };
        }
      };

      const addDelegatePledge = (stGiver, idPledge) => {
        const pledge = this.pledges[idPledge];
        stGiver.notAssigned.pledges.push(idPledge);
        let list = stGiver.notAssigned.delegates;
        for (let i = 0; i < pledge.delegationChain.length; i += 1) {
          const idDelegate = pledge.delegationChain[i];
          addDelegate(list, idDelegate);
          list = list[idDelegate].delegates;
        }
      };

      const addCampaignPledge = (stGiver, idPledge) => {
        const pledge = this.pledges[idPledge];

        const campaignList = [];
        let n = pledge;
        while (n.oldNode) {
          campaignList.unshift(n.owner);
          n = this.pledges[n.oldNode];
        }

        let list = stGiver.commitedCampaigns;
        for (let j = 0; j < campaignList.length; j += 1) {
          addCampaign(list, campaignList[j]);
          list[campaignList[j]].pledges.push(idPledge);
          list = list[campaignList[j]].commitedCampaigns;
        }
      };

      for (let i = 0; i < this.pledges; i += 1) {
        const idPledge = this.pledges[i];
        const idGiver = getGiver(idPledge);
        addGiver(giversState, idGiver);
        const stGiver = giversState[idGiver];
        const pledge = this.pledges[idPledge];
        if ((pledge.owner === idGiver) && (pledge.precommitedCampaign === 0)) {
          addDelegatePledge(stGiver, idPledge);
        } else if ((pledge.owner === idGiver) && (pledge.precommitedCampaign !== 0)) {
          addCampaign(stGiver.precommitedCampaigns, pledge.precommitedCampaign);
          stGiver.precommitedCampaigns[pledge.precommitedCampaign].pledges.push(idPledge);
        } else {
          addCampaignPledge(stGiver, idPledge);
        }
      }

      this.giverssState = giversState;
    }
  };
};
