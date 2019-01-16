module.exports = function(liquidPledging) {
  function getPledge(idPledge) {
    const pledge = {
      delegates: [],
    };

    return liquidPledging
      .getPledge(idPledge)
      .then(res => {
        pledge.amount = res.amount;
        pledge.owner = res.owner;
        pledge.token = res.token;

        if (res.intendedProject) {
          pledge.intendedProject = res.intendedProject;
          pledge.commmitTime = res.commitTime;
        }
        if (res.oldPledge) {
          pledge.oldPledge = res.oldPledge;
        }
        if (res.pledgeState === '0') {
          pledge.pledgeState = 'Pledged';
        } else if (res.pledgeState === '1') {
          pledge.pledgeState = 'Paying';
        } else if (res.pledgeState === '2') {
          pledge.pledgeState = 'Paid';
        } else {
          pledge.pledgeState = 'Unknown';
        }

        const promises = [];
        for (let i = 1; i <= res.nDelegates; i += 1) {
          promises.push(
            liquidPledging.getPledgeDelegate(idPledge, i).then(r => ({
              id: r.idDelegate,
              addr: r.addr,
              name: r.name,
              url: r.url,
            })),
          );
        }

        return Promise.all(promises);
      })
      .then(delegates => {
        pledge.delegates = delegates;
        return pledge;
      });
  }

  function getAdmin(idAdmin) {
    const admin = {};
    return liquidPledging.getPledgeAdmin(idAdmin).then(res => {
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
      if (admin.type === 'Project') {
        admin.parentProject = res.parentProject;
        admin.canceled = res.canceled;
      }
      admin.plugin = res.plugin;
      return admin;
    });
  }
  return {
    getState() {
      const getPledges = () =>
        liquidPledging.numberOfPledges().then(nPledges => {
          const promises = [];
          for (let i = 1; i <= nPledges; i += 1) {
            promises.push(getPledge(i));
          }
          return Promise.all(promises);
        });

      const getAdmins = () =>
        liquidPledging.numberOfPledgeAdmins().then(nAdmins => {
          const promises = [];
          for (let i = 1; i <= nAdmins; i += 1) {
            promises.push(getAdmin(i));
          }

          return Promise.all(promises);
        });

      return Promise.all([getPledges(), getAdmins()]).then(([pledges, admins]) => ({
        pledges: [null, ...pledges],
        admins: [null, ...admins],
      }));
    },
  };
};
