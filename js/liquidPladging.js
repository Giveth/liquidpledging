const LiquidPledgingAbi = require("../build/contracts/LiquidPledging.json").abi;

module.exports = class LiquidPledging {
    constructor(web3, address) {
      this.notes = [];
      this.managers = [];
    }

    getDonorInfo(idDonor) {
      const st = {};

      return st;
    }
}

/*
managers = []


donors = [
    "donor"/idDonor(d1,d2)/"NotAssigned"/idDelegate1/idDelegate2
                   /"PreAssigned"/idProject1
                   /"Assigned"/idProject1/idProject2
                   /"Spended"/idProject1/idProject2

    donor(d1,d2)/project1(d3,d4)/idProject2(d5, d6)/["Paying,Paid"]
                                                    ["Preassigned: IDTIME"]
                       /"Assigned"/donor(d1,d2)/project1(d3,d4)
                       /"Spent"/idProject1/idProject2/idProject(da,db)

]

console.log(JSON.stringify(LiquidPledgingAbi));
*/
