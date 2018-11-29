import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import Giving from './components/Giving';

const { getNetworkType } = web3.eth.net;

class App extends React.Component {
  constructor(props) {
    super(props)
  }
  state = { admin: false };

  componentDidMount(){
    EmbarkJS.onReady(async (err) => {
      getNetworkType().then(network => {
        //TODO add window.ethereum.enable();
        const { environment } = EmbarkJS
        this.setState({ network, environment })
      });
    });
  }

  render() {
    return (
      <div>
        <Giving />
      </div>
    )
  }
}

export default App;
