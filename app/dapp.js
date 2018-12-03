import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import Divider from '@material-ui/core/Divider';
import Button from '@material-ui/core/Button';
import AddFunder from './components/AddFunder';
import CreateFunding from './components/CreateFunding';
import FunderProfilesTable from './components/FunderProfilesTable'
import PledgesTable from './components/PledgesTable'
import { initVaultAndLP, vaultPledgingNeedsInit, standardTokenApproval, getLpAllowance } from './utils/initialize'
import { getProfileEvents, formatFundProfileEvent } from './utils/events';
import { getAllPledges, appendToExistingPledges } from './utils/pledges';

const { getNetworkType } = web3.eth.net;

class App extends React.Component {
  constructor(props) {
    super(props)
  }
  state = { admin: false };

  componentDidMount(){
    EmbarkJS.onReady(async (err) => {
      getNetworkType().then(async network => {
        const { environment } = EmbarkJS
        const needsInit = await vaultPledgingNeedsInit()
        const lpAllowance = await getLpAllowance()
        const fundProfiles = await getProfileEvents()
        const allPledges = await getAllPledges()
        this.setState({
          network,
          environment,
          needsInit: needsInit === 0,
          lpAllowance,
          fundProfiles,
          allPledges
        })
      });
    });
  }

  appendFundProfile = async event => {
    const formattedEvent = await formatFundProfileEvent(event)
    this.setState((state) => {
      const { fundProfiles } = state;
      return {
        ...state,
        fundProfiles: [ ...fundProfiles, formattedEvent ]
      }
    })
  }

  appendPledges = () => {
    const { allPledges } = this.state
    appendToExistingPledges(allPledges, this.setState)
  }

  render() {
    const { needsInit, lpAllowance, fundProfiles, allPledges } = this.state;
    const { appendFundProfile, appendPledges } = this;
    return (
      <div>
        {allPledges && <PledgesTable data={allPledges} />}
        {fundProfiles && <FunderProfilesTable data={fundProfiles} />}
        <AddFunder appendFundProfile={appendFundProfile} />
        <Divider variant="middle" />
        <CreateFunding refreshTable={appendPledges} />
        {needsInit && <Button variant="outlined" color="secondary" onClick={initVaultAndLP}>
          Initialize Contracts
        </Button>}
        <Button variant="outlined" color="primary" onClick={standardTokenApproval}>
          GIVE VAULT TOKEN APPROVAL
        </Button>
      </div>
    )
  }
}

export default App;
