class LiquidPledgingState {
  constructor(liquidPledging) {
    this.$lp = liquidPledging;
  }

  getPledge(idPledge) {
    const pledge = {
      delegates: [],
    };

    return this.$lp.getPledge(idPledge)
    .then((res) => {
      pledge.amount = res[0];
      pledge.owner = res[1];
      pledge.nDelegates = res[2];
      pledge.token = res[6];

      if (res[3]) { 
        pledge.intendedProject =res[3];
        pledge.commitTime = res[4];
      }
      
      if (res[5]) {
        pledge.oldPledge = res[5];
      }
      if (res[7] == '0') {
        pledge.pledgeState = 'Pledged';
      } else if (res[7] == '1') {
        pledge.pledgeState = 'Paying';
      } else if (res[7] == '2') {
        pledge.pledgeState = 'Paid';
      } else {
        pledge.pledgeState = 'Unknown';
      }
      
      const promises = [];
      for (let i = 1; i <= res[2].toNumber(); i += 1) {
        promises.push(
          this.$lp.getPledgeDelegate(idPledge, i)
          .then(r => ({
            id: r[0],
            addr: r[1],
            name: r[2],
          })),
          );
      }

      return Promise.all(promises);
    })
    .then((delegates) => {
      pledge.delegates = delegates;
      return pledge;
    });
  }

  getAdmin(idAdmin) {
    const admin = {};
    return this.$lp.getPledgeAdmin(idAdmin)
    .then((res) => {
      if (res[0] == '0') {
        admin.type = 'Giver';
      } else if (res[0] == '1') {
        admin.type = 'Delegate';
      } else if (res[0] == '2') {
        admin.type = 'Project';
      } else {
        admin.type = 'Unknown';
      }
      admin.addr = res[1];
      admin.name = res[2];
      admin.url = res[3];
      admin.commitTime = res[4];
      if (admin.type === 'Project') {
        admin.parentProject = res[5];
        admin.canceled = res[6];
      }
      admin.plugin = res[7];
      return admin;
    });
  }

  getState() {
    const getPledges = () => this.$lp.numberOfPledges()
    .then((nPledges) => {
      const promises = [];
      for (let i = 1; i <= nPledges; i += 1) {
        promises.push(this.getPledge(i));
      }
      return Promise.all(promises);
    });

    const getAdmins = () => this.$lp.numberOfPledgeAdmins()
    .then((nAdmins) => {
      const promises = [];
      for (let i = 1; i <= nAdmins; i += 1) {
        promises.push(this.getAdmin(i));
      }

      return Promise.all(promises);
    });

    return Promise.all([getPledges(), getAdmins()])
    .then(([pledges, admins]) => ({
      pledges: [null, ...pledges],
      admins: [null, ...admins],
    }));
  }
}

module.exports = LiquidPledgingState;
