import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import AddFunder from './components/AddFunder';
import CreateFunding from './components/CreateFunding';

const { getNetworkType } = web3.eth.net;

class App extends React.Component {
  constructor(props) {
    super(props)
  }
  state = { admin: false };

  componentDidMount(){
    EmbarkJS.onReady(async (err) => {
      getNetworkType().then(network => {
        const { environment } = EmbarkJS
        this.setState({ network, environment })
      });
    });
  }

  render() {
    return (
      <div>
        <AddFunder />
        <CreateFunding />
      </div>
    )
  }
}

export default App;
