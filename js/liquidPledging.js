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
      this.b = "xxxxxxx b xxxxxxxx";
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
        note.proposedProject = res[3].toNumber();
        note.commmitTime = res[4].toNumber();
      }
      if (res[5].toNumber()) {
        note.oldProject = res[5].toNumber();
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
        manager.paymentState = 'Donor';
      } else if (res[0].toNumber() === 1) {
        manager.paymentState = 'Delegate';
      } else if (res[0].toNumber() === 2) {
        manager.paymentState = 'Project';
      } else {
        manager.paymentState = 'Unknown';
      }
      manager.addr = res[1];
      manager.name = res[2];
      manager.commitTime = res[3].toNumber();
      if (manager.paymentState === 'Project') {
        manager.parentProject = res[4];
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

    generateDonorsState() {
      const donorsState = [];

      const getDonor = (idNote) => {
        let note = this.notes[idNote];
        while (note.oldNode) note = this.notes[idNote];
        return note.owner;
      };

      // Add a donor structure to the list
      const addDonor = (_list, idDonor) => {
        const list = _list;
        if (!list[idDonor]) {
          list[idDonor] = {
            idDonor,
            notAssigned: {
              notes: [],
              delegates: [],
            },
            precommitedProjects: [],
            commitedProjects: [],
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

      const addProject = (_list, idProject) => {
        const list = _list;
        if (!list[idProject]) {
          list[idProject] = {
            idProject,
            notes: [],
            commitedProjects: [],
            name: this.managers[idProject].name,
            commitTime: this.managers[idProject].commitTime,
            owner: this.managers[idProject].owner,
            parentProject: this.managers[idProject].parentProject,
          };
        }
      };

      const addDelegateNote = (stDonor, idNote) => {
        const note = this.notes[idNote];
        stDonor.notAssigned.notes.push(idNote);
        let list = stDonor.notAssigned.delegates;
        for (let i = 0; i < note.delegationChain.length; i += 1) {
          const idDelegate = note.delegationChain[i];
          addDelegate(list, idDelegate);
          list = list[idDelegate].delegates;
        }
      };

      const addProjectNote = (stDonor, idNote) => {
        const note = this.notes[idNote];

        const projectList = [];
        let n = note;
        while (n.oldNode) {
          projectList.unshift(n.owner);
          n = this.notes[n.oldNode];
        }

        let list = stDonor.commitedProjects;
        for (let j = 0; j < projectList.length; j += 1) {
          addProject(list, projectList[j]);
          list[projectList[j]].notes.push(idNote);
          list = list[projectList[j]].commitedProjects;
        }
      };

      for (let i = 0; i < this.notes; i += 1) {
        const idNote = this.notes[i];
        const idDonor = getDonor(idNote);
        addDonor(donorsState, idDonor);
        const stDonor = donorsState[idDonor];
        const note = this.notes[idNote];
        if ((note.owner === idDonor) && (note.precommitedProject === 0)) {
          addDelegateNote(stDonor, idNote);
        } else if ((note.owner === idDonor) && (note.precommitedProject !== 0)) {
          addProject(stDonor.precommitedProjects, note.precommitedProject);
          stDonor.precommitedProjects[note.precommitedProject].notes.push(idNote);
        } else {
          addProjectNote(stDonor, idNote);
        }
      }

      this.donorsState = donorsState;
    }
  };
};
