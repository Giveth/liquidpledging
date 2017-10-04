const LiquidPledgingAbi = require('../build/LiquidPledging.sol').LiquidPledgingAbi;
const LiquidPledgingCode = require('../build/LiquidPledging.sol').LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require('../build/LiquidPledgingMock.sol').LiquidPledgingMockByteCode;
const generateClass = require('eth-contract-class').default;

module.exports = (test) => {
  const $abi = (test) ? LiquidPledgingMockAbi : LiquidPledgingAbi;
  const $byteCode = (test) ? LiquidPledgingMockCode : LiquidPledgingCode;

  const LiquidPledging = generateClass($abi, $byteCode);

  LiquidPledging.prototype.$getPledge = function (idPledge) {
    const pledge = {
      delegates: [],
    };

    return this.getPledge(idPledge)
      .then((res) => {
        pledge.amount = res.amount;
        pledge.owner = res.owner;

        if (res.intendedProject) {
          pledge.intendedProject = res.intendedProject;
          pledge.commmitTime = res.commitTime;
        }
        if (res.oldPledge) {
          pledge.oldPledge = res.oldPledge;
        }
        if (res.paymentState === '0') {
          pledge.paymentState = 'Pledged';
        } else if (res.paymentState === '1') {
          pledge.paymentState = 'Paying';
        } else if (res.paymentState === '2') {
          pledge.paymentState = 'Paid';
        } else {
          pledge.paymentState = 'Unknown';
        }

        const promises = [];
        for (let i = 1; i <= res.nDelegates; i += 1) {
          promises.push(
            this.getPledgeDelegate(idPledge, i)
              .then(r => ({
                id: r.idDelegate,
                addr: r.addr,
                name: r.name,
                url: r.url
              })),
          );
        }

        return Promise.all(promises);
      })
      .then((delegates) => {
        pledge.delegates = delegates;
        return pledge;
      });
  };

  LiquidPledging.prototype.$getAdmin = function (idAdmin) {
    const admin = {};
    return this.getPledgeAdmin(idAdmin)
      .then((res) => {
        if (res.adminType === '0') {
          admin.type = 'Giver';
        } else if (res.adminType === '1') {
          admin.type = 'Delegate';
        } else if (res.adminType === '2') {
          admin.type = 'Project';
        } else {
          admin.type = 'Unknown';
        }
        admin.addr = res.addr;
        admin.name = res.name;
        admin.url = res.url;
        admin.commitTime = res.commitTime;
        if (admin.paymentState === 'Project') {
          admin.parentProject = res.parentProject;
          admin.canceled = res.canceled;
        }
        admin.plugin = res.plugin;
        admin.canceled = res.canceled;
        return admin;
      });
  };

  LiquidPledging.prototype.getState = function () {
    const getPledges = () => this.numberOfPledges()
        .then((nPledges) => {
          const promises = [];
          for (let i = 1; i <= nPledges; i += 1) {
            promises.push(this.$getPledge(i));
          }
          return Promise.all(promises);
        });

    const getAdmins = () => this.numberOfPledgeAdmins()
      .then((nAdmins) => {
        const promises = [];
        for (let i = 1; i <= nAdmins; i += 1) {
          promises.push(this.$getAdmin(i));
        }

        return Promise.all(promises);
      });

    return Promise.all([getPledges(), getAdmins()])
        .then(([pledges, admins]) => ({
          pledges: [null, ...pledges],
          admins: [null, ...admins],
        }));
  };

  LiquidPledging.prototype.generateGiversState = function () {
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
          name: this.admins[idDelegate].name,
          url: this.admins[idDelegate].url,
          pledges: [],
          delegtes: [],
        };
      }
    };

    const addProject = (_list, idProject) => {
      const list = _list;
      if (!list[idProject]) {
        list[idProject] = {
          idProject,
          pledges: [],
          commitedProjects: [],
          name: this.admins[idProject].name,
          url: this.admins[idProject].url,
          commitTime: this.admins[idProject].commitTime,
          owner: this.admins[idProject].owner,
          parentProject: this.admins[idProject].parentProject,
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

    const addProjectPledge = (stGiver, idPledge) => {
      const pledge = this.pledges[idPledge];

      const crojectList = [];
      let n = pledge;
      while (n.oldNode) {
        crojectList.unshift(n.owner);
        n = this.pledges[n.oldNode];
      }

      let list = stGiver.commitedProjects;
      for (let j = 0; j < crojectList.length; j += 1) {
        addProject(list, crojectList[j]);
        list[crojectList[j]].pledges.push(idPledge);
        list = list[crojectList[j]].commitedProjects;
      }
    };

    for (let i = 0; i < this.pledges; i += 1) {
      const idPledge = this.pledges[i];
      const idGiver = getGiver(idPledge);
      addGiver(giversState, idGiver);
      const stGiver = giversState[idGiver];
      const pledge = this.pledges[idPledge];
      if ((pledge.owner === idGiver) && (pledge.precommitedProject === 0)) {
        addDelegatePledge(stGiver, idPledge);
      } else if ((pledge.owner === idGiver) && (pledge.precommitedProject !== 0)) {
        addProject(stGiver.precommitedProjects, pledge.precommitedProject);
        stGiver.precommitedProjects[pledge.precommitedProject].pledges.push(idPledge);
      } else {
        addProjectPledge(stGiver, idPledge);
      }
    }

    this.giversState = giversState;
  };

  return LiquidPledging;
};
