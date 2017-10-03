/* eslint-disable no-await-in-loop */
const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
const runethtx = require('runethtx');


module.exports = (test) => {
  const LiquidPladgingContract = test ?
  runethtx.generateClass(LiquidPledgingMockAbi, LiquidPledgingMockCode) :
  runethtx.generateClass(LiquidPledgingAbi, LiquidPledgingCode);

  return class LiquidPledging extends LiquidPladgingContract {
    constructor(web3, address) {
      super(web3, address);
      this.notes = [];
      this.managers = [];
      this.b = 'xxxxxxx b xxxxxxxx';
    }

    async $getNote(idNote) {
      const note = {
        delegates: [],
      };
      const res = await this.getNote(idNote);
      note.amount = res[0];
      note.owner = res[1];
      for (let i = 1; i <= res[2].toNumber(); i += 1) {
        const delegate = {};
        const resd = await this.getNoteDelegate(idNote, i);
        delegate.id = resd[0].toNumber();
        delegate.addr = resd[1];
        delegate.name = resd[2];
        note.delegates.push(delegate);
      }
      if (res[3].toNumber()) {
        note.proposedCampaign = res[3].toNumber();
        note.commmitTime = res[4].toNumber();
      }
      if (res[5].toNumber()) {
        note.oldCampaign = res[5].toNumber();
      }
      if (res[6].toNumber() === 0) {
        note.paymentState = 'NotPaid';
      } else if (res[6].toNumber() === 1) {
        note.paymentState = 'Paying';
      } else if (res[6].toNumber() === 2) {
        note.paymentState = 'Paid';
      } else {
        note.paymentState = 'Unknown';
      }
      return note;
    }

    async $getManager(idManager) {
      const manager = {};
      const res = await this.getNoteManager(idManager);
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
        notes: [null],
        managers: [null],
      };
      const nNotes = await this.numberOfNotes();
      for (let i = 1; i <= nNotes; i += 1) {
        const note = await this.$getNote(i);
        st.notes.push(note);
      }

      const nManagers = await this.numberOfNoteManagers();
      for (let i = 1; i <= nManagers; i += 1) {
        const manager = await this.$getManager(i);
        st.managers.push(manager);
      }
      return st;
    }

    generateGiversState() {
      const giversState = [];

      const getGiver = (idNote) => {
        let note = this.notes[idNote];
        while (note.oldNode) note = this.notes[idNote];
        return note.owner;
      };

      // Add a giver structure to the list
      const addGiver = (_list, idGiver) => {
        const list = _list;
        if (!list[idGiver]) {
          list[idGiver] = {
            idGiver,
            notAssigned: {
              notes: [],
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
            notes: [],
            delegtes: [],
          };
        }
      };

      const addCampaign = (_list, idCampaign) => {
        const list = _list;
        if (!list[idCampaign]) {
          list[idCampaign] = {
            idCampaign,
            notes: [],
            commitedCampaigns: [],
            name: this.managers[idCampaign].name,
            commitTime: this.managers[idCampaign].commitTime,
            owner: this.managers[idCampaign].owner,
            parentCampaign: this.managers[idCampaign].parentCampaign,
          };
        }
      };

      const addDelegateNote = (stGiver, idNote) => {
        const note = this.notes[idNote];
        stGiver.notAssigned.notes.push(idNote);
        let list = stGiver.notAssigned.delegates;
        for (let i = 0; i < note.delegationChain.length; i += 1) {
          const idDelegate = note.delegationChain[i];
          addDelegate(list, idDelegate);
          list = list[idDelegate].delegates;
        }
      };

      const addCampaignNote = (stGiver, idNote) => {
        const note = this.notes[idNote];

        const campaignList = [];
        let n = note;
        while (n.oldNode) {
          campaignList.unshift(n.owner);
          n = this.notes[n.oldNode];
        }

        let list = stGiver.commitedCampaigns;
        for (let j = 0; j < campaignList.length; j += 1) {
          addCampaign(list, campaignList[j]);
          list[campaignList[j]].notes.push(idNote);
          list = list[campaignList[j]].commitedCampaigns;
        }
      };

      for (let i = 0; i < this.notes; i += 1) {
        const idNote = this.notes[i];
        const idGiver = getGiver(idNote);
        addGiver(giversState, idGiver);
        const stGiver = giversState[idGiver];
        const note = this.notes[idNote];
        if ((note.owner === idGiver) && (note.precommitedCampaign === 0)) {
          addDelegateNote(stGiver, idNote);
        } else if ((note.owner === idGiver) && (note.precommitedCampaign !== 0)) {
          addCampaign(stGiver.precommitedCampaigns, note.precommitedCampaign);
          stGiver.precommitedCampaigns[note.precommitedCampaign].notes.push(idNote);
        } else {
          addCampaignNote(stGiver, idNote);
        }
      }

      this.giverssState = giversState;
    }
  };
};
