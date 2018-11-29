import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";

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
        console.log({LiquidPledgingMock, LPVault})
        this.addGiver();
      });
    });
  }

  addGiver = async () => {
    const { addGiver, numberOfPledgeAdmins, getPledgeAdmin } = LiquidPledgingMock.methods;
    const account = await web3.eth.getCoinbase();
    const name = 'Giver1';
    const url = 'urlGiver';
    const commitTime = 86400;
    const plugin = 0;
    const params = { from: account, gas: 1000000 };
    const args = [name, url, commitTime, plugin];
    console.log({account})
    addGiver(...args)
           .estimateGas({from: account})
           .then(async gas => {
             console.log({gas})
             addGiver(...args).send({ from: account, gas: gas + 100 })
             const nAdmins = await numberOfPledgeAdmins().call();
             console.log({nAdmins});
             const res = await getPledgeAdmin(0).call();
             console.log({res})
           })
           .catch(e => console.log({e}));
  }

  render() {
    return (
      <div>
        <div>Hello world!</div>
      </div>
    )
  }
}

export default App;
