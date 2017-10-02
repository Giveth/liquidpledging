const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = (test) => {
  const $abi = (test) ? LiquidPledgingMockAbi : LiquidPledgingAbi;
  const $byteCode = (test) ? LiquidPledgingMockCode : LiquidPledgingCode;

  const LiquidPledging = generateClass($abi, $byteCode);

  LiquidPledging.prototype.$getNote = function (idNote) {
    const note = {
      delegates: [],
    };

    return this.getNote(idNote)
      .then((res) => {
        note.amount = res.amount;
        note.owner = res.owner;

        if (res.proposedProject) {
          note.proposedProject = res.proposedProject;
          note.commmitTime = res.commitTime;
        }
        if (res.oldNote) {
          note.oldProject = res.oldNote;
        }
        if (res.paymentState === '0') {
          note.paymentState = 'NotPaid';
        } else if (res.paymentState === '1') {
          note.paymentState = 'Paying';
        } else if (res.paymentState === '2') {
          note.paymentState = 'Paid';
        } else {
          note.paymentState = 'Unknown';
        }

        const promises = [];
        for (let i = 1; i <= res.nDelegates; i += 1) {
          promises.push(
            this.getNoteDelegate(idNote, i)
              .then(r => ({
                id: r.idDelegate,
                addr: r.addr,
                name: r.name,
              })),
          );
        }

        return Promise.all(promises);
      })
      .then((delegates) => {
        note.delegates = delegates;
        return note;
      });
  };

  LiquidPledging.prototype.$getManager = function (idManager) {
    const manager = {};
    return this.getNoteManager(idManager)
      .then((res) => {
        if (res.managerType === '0') {
          manager.type = 'Donor';
        } else if (res.managerType === '1') {
          manager.type = 'Delegate';
        } else if (res.managerType === '2') {
          manager.type = 'Project';
        } else {
          manager.type = 'Unknown';
        }
        manager.addr = res.addr;
        manager.name = res.name;
        manager.commitTime = res.commitTime;
        if (manager.paymentState === 'Project') {
          manager.parentProject = res.parentProject;
          manager.canceled = res.canceled;
        }
        manager.plugin = res.plugin;
        manager.canceled = res.canceled;
        return manager;
      });
  };

  LiquidPledging.prototype.getState = function () {
    const getNotes = () => this.numberOfNotes()
        .then((nNotes) => {
          const promises = [];
          for (let i = 1; i <= nNotes; i += 1) {
            promises.push(this.$getNote(i));
          }
          return Promise.all(promises);
        });

    const getManagers = () => this.numberOfNoteManagers()
      .then((nManagers) => {
        const promises = [];
        for (let i = 1; i <= nManagers; i += 1) {
          promises.push(this.$getManager(i));
        }

        return Promise.all(promises);
      });

    return Promise.all([getNotes(), getManagers()])
        .then(([notes, managers]) => ({
          notes: [null, ...notes],
          managers: [null, ...managers],
        }));
  };

  LiquidPledging.prototype.generateDonorsState = function () {
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
  };

  return LiquidPledging;
};
