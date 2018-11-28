import React from 'react';
import EmbarkJS from 'Embark/EmbarkJS';
import web3 from "Embark/web3";

const { getNetworkType } = web3.eth.net;

class App extends React.Component {
  constructor(props) {
    super(props)
  }
  state = { admin: false };

  componentDidMount(){
    EmbarkJS.onReady((err) => {
      getNetworkType().then(network => {
        const { environment } = EmbarkJS
        this.setState({ network, environment })
      });
    });
  }

  render() {
    return (
      <div>Hello world!</div>
    )
  }
}
