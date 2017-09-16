/* eslint-disable no-await-in-loop */
const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;

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

// estimate gas before send if necessary
const sendWithDefaults = (web3, txObject) => {
  const origSend = txObject.send;

  // eslint-disable-next-line no-param-reassign
  txObject.send = (opts = {}, cb) => estimateGas(web3, txObject, opts)
      .then((gas) => {
        Object.assign(opts, { gas });
        return (cb) ? origSend(opts, cb) : origSend(opts);
      });

  return txObject;
};

const extendMethod = (web3, method) => (...args) => sendWithDefaults(web3, method(...args));


module.exports = (test) => {
  const $abi = (test) ? LiquidPledgingMockAbi : LiquidPledgingAbi;
  const $byteCode = (test) ? LiquidPledgingMockCode : LiquidPledgingCode;


  return class LiquidPledging {
    constructor(web3, address) {
      checkWeb3(web3);

      this.$web3 = web3;
      this.$address = address;
      this.$contract = new web3.eth.Contract($abi, address);
      this.$abi = $abi;
      this.$byteCode = $byteCode;

      // helpers
      this.$toNumber = web3.utils.toBN;
      this.$toDecimal = web3.utils.toDecimal;

      this.notes = [];
      this.managers = [];

      Object.keys(this.$contract.methods).forEach((key) => {
        this[key] = extendMethod(web3, this.$contract.methods[key]);
      });

      // set default from address
      web3.eth.getAccounts()
        .then((accounts) => {
          this.$contract.options.from = (accounts.length > 0) ? accounts[0] : undefined;
        });
    }

    async $getNote(idNote) {
      const note = {
        delegates: [],
      };
      const res = await this.getNote(idNote).call();
      note.amount = this.$toNumber(res.amount);
      note.owner = res.owner;
      for (let i = 1; i <= this.$toDecimal(res.nDelegates); i += 1) {
        const delegate = {};
        const resd = await this.getNoteDelegate(idNote, i).call();
        delegate.id = this.$toDecimal(resd.idDelegate);
        delegate.addr = resd.addr;
        delegate.name = resd.name;
        note.delegates.push(delegate);
      }
      if (res.proposedProject) {
        note.proposedProject = this.$toDecimal(res.proposedProject);
        note.commmitTime = this.$toDecimal(res.commitTime);
      }
      if (res.oldNote) {
        note.oldProject = this.$toDecimal(res.oldNote);
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
      return note;
    }

    async $getManager(idManager) {
      const manager = {};
      const res = await this.getNoteManager(idManager).call();
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
      manager.commitTime = this.$toDecimal(res.commitTime);
      if (manager.paymentState === 'Project') {
        manager.parentProject = res.parentProject;
        manager.canceled = res.canceled;
      }
      return manager;
    }

    async getState() {
      const st = {
        notes: [null],
        managers: [null],
      };
      const nNotes = await this.numberOfNotes().call();
      for (let i = 1; i <= nNotes; i += 1) {
        const note = await this.$getNote(i);
        st.notes.push(note);
      }

      const nManagers = await this.numberOfNoteManagers().call();
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

    static new(web3, vault, opts = {}) {
      const deploy = new web3.eth.Contract($abi)
              .deploy({
                data: $byteCode,
                arguments: [vault],
              });

      const getAccount = () => {
        if (opts.from) return Promise.resolve(opts.from);

        return web3.eth.getAccounts()
            // eslint-disable-next-line no-confusing-arrow
            .then(accounts => (accounts.length > 0) ? accounts[0] : undefined);
      };

      return getAccount()
          .then(account => Object.assign(opts, { from: account }))
          .then(() => sendWithDefaults(web3, deploy).send(opts))
          .then(contract => new LiquidPledging(web3, contract.options.address));
    }
  };
};
