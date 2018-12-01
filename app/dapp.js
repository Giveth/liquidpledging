import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import Divider from '@material-ui/core/Divider';
import AddFunder from './components/AddFunder';
import CreateFunding from './components/CreateFunding';
import { initVaultAndLP, vaultPledgingNeedsInit, standardTokenApproval } from './utils/initialize'

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
        const needsInit = await vaultPledgingNeedsInit();
        this.setState({ network, environment })

        //methods during testing to help setup
        if (environment === 'development') standardTokenApproval()
        if (!needsInit) initVaultAndLP(LiquidPledgingMock, LPVault)
      });
    });
  }

  render() {
    return (
      <div>
        <AddFunder />
        <Divider variant="middle" />
        <CreateFunding />
      </div>
    )
  }
}

export default App;
