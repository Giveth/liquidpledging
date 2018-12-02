import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import Divider from '@material-ui/core/Divider';
import Button from '@material-ui/core/Button';
import AddFunder from './components/AddFunder';
import CreateFunding from './components/CreateFunding';
import FunderProfilesTable from './components/FunderProfilesTable.jsx'
import { initVaultAndLP, vaultPledgingNeedsInit, standardTokenApproval, getLpAllowance } from './utils/initialize'
import { getUserFundProfiles } from './utils/events';

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
        const fundProfiles = await getUserFundProfiles()
        this.setState({
          network,
          environment,
          needsInit: needsInit === 0,
          lpAllowance,
          fundProfiles
        })
      });
    });
  }

  render() {
    const { needsInit, lpAllowance, fundProfiles } = this.state;
    return (
      <div>
        {fundProfiles && <FunderProfilesTable data={fundProfiles} />}
        <AddFunder />
        <Divider variant="middle" />
        <CreateFunding />
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
