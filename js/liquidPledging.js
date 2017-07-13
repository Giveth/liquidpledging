const LiquidPledgingAbi = require("../build/LiquidPledging.sol").LiquidPledgingAbi;
const LiquidPledgingCode = require("../build/LiquidPledging.sol").LiquidPledgingByteCode;
const LiquidPledgingMockAbi = require("../build/LiquidPledgingMock.sol").LiquidPledgingMockAbi;
const LiquidPledgingMockCode = require("../build/LiquidPledgingMock.sol").LiquidPledgingMockByteCode;
const runethtx = require("runethtx");

module.exports = (test) => {
  const LiquidPladgingContract = test ?
        runethtx.generateClass(LiquidPledgingMockAbi, LiquidPledgingMockCode) :
        runethtx.generateClass(LiquidPledgingAbi, LiquidPledgingCode);

  return class LiquidPledging extends LiquidPladgingContract {
    constructor(web3, address) {
        super(web3, address);
        this.notes = [];
        this.managers = [];
    }

    getFullState(cb) {
        const liquidPledging = this.web3.eth.contract(LiquidPledgingAbi).at(this.address);
    }

    generateDonorsState() {
        const donorsState = [];

        const getDonor = (idNote) => {
            let note = this.notes[ idNote ];
            while (note.oldNode) note = this.notes[ idNote ];
            return note.owner;
        };

        const addDonor = (_list, idDonor) => {
            const list = _list;
            if (!list[ idDonor ]) {
                list[ idDonor ] = {
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

        const addDelegate = (_list, idDelegate) => {
            const list = _list;
            if (!list[ idDelegate ]) {
                list[ idDelegate ] = {
                    idDelegate,
                    name: this.managers[ idDelegate ].name,
                    notes: [],
                    delegtes: [],
                };
            }
        };

        const addProject = (_list, idProject) => {
            const list = _list;
            if (!list[ idProject ]) {
                list[ idProject ] = {
                    idProject,
                    notes: [],
                    commitedProjects: [],
                    name: this.managers[ idProject ].name,
                    commitTime: this.managers[ idProject ].commitTime,
                    owner: this.managers[ idProject ].owner,
                    reviewer: this.managers[ idProject ].reviewer,
                };
            }
        };

        const addDelegateNote = (stDonor, idNote) => {
            const note = this.notes[ idNote ];
            stDonor.notAssigned.notes.push(idNote);
            let list = stDonor.notAssigned.delegates;
            for (let i = 0; i < note.delegationChain.length; i += 1) {
                const idDelegate = note.delegationChain[ i ];
                addDelegate(list, idDelegate);
                list = list[ idDelegate ].delegates;
            }
        };

        const addProjectNote = (stDonor, idNote) => {
            const note = this.notes[ idNote ];

            const projectList = [];
            let n = note;
            while (n.oldNode) {
                projectList.unshift(n.owner);
                n = this.notes[ n.oldNode ];
            }

            let list = stDonor.commitedProjects;
            for (let j = 0; j < projectList.length; j += 1) {
                addProject(list, projectList[ j ]);
                list[ projectList[ j ] ].notes.push(idNote);
                list = list[ projectList[ j ] ].commitedProjects;
            }
        };

        for (let i = 0; i < this.notes; i += 1) {
            const idNote = this.notes[ i ];
            const idDonor = getDonor(idNote);
            addDonor(donorsState, idDonor);
            const stDonor = donorsState[ idDonor ];
            const note = this.notes[ idNote ];
            if ((note.owner === idDonor) && (note.precommitedProject === 0)) {
                addDelegateNote(stDonor, idNote);
            } else if ((note.owner === idDonor) && (note.precommitedProject === 0)) {
                addProject(stDonor.precommitedProjects, note.precommitedProject);
                stDonor.precommitedProjects[ note.precommitedProject ].notes.push(idNote);
            } else {
                addProjectNote(stDonor, idNote);
            }
        }

        this.donorsState = donorsState;
    }
  };
};
