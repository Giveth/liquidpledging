import React from 'react'
import { HashRouter as Router, Route, Link, Switch } from 'react-router-dom'
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import web3 from "Embark/web3";
import Divider from '@material-ui/core/Divider';
import AddFunder from './components/AddFunder';
import CreateFunding from './components/CreateFunding';
import FunderProfilesTable from './components/FunderProfilesTable'
import PledgesTable from './components/PledgesTable'
import { initVaultAndLP, vaultPledgingNeedsInit, standardTokenApproval, getLpAllowance } from './utils/initialize'
import { getAllLPEvents, getAllVaultEvents, getProfileEvents, formatFundProfileEvent, getAuthorizedPayments } from './utils/events'
import { getAllPledges, appendToExistingPledges, transferBetweenPledges } from './utils/pledges';
import { FundingContext } from './context'
import { cancelProfile } from './utils/fundProfiles'
import TransfersGraph from './components/TransfersGraph'
import MainCointainer from './components/MainCointainer'
import ContractAdmin from './components/ContractAdmin'

const { getNetworkType } = web3.eth.net

class App extends React.Component {
  state = {
    lpAllowance: 0,
    fundProfiles: [],
    allPledges: [],
    needsInit: true
  };

  componentDidMount(){
    EmbarkJS.onReady(async (err) => {
      getNetworkType().then(async network => {
        const { environment } = EmbarkJS
        const isInitialized = await vaultPledgingNeedsInit()
        if (!!isInitialized) {
          console.log('mock_time:', await LiquidPledgingMock.mock_time.call())
          const lpAllowance = await getLpAllowance()
          const fundProfiles = await getProfileEvents()
          const allPledges = await getAllPledges()
          const authorizedPayments = await getAuthorizedPayments()
          const account = await web3.eth.getCoinbase()
          const allLpEvents = await getAllLPEvents()
          const allVaultEvents = await getAllVaultEvents()
          const transfers = allLpEvents.filter(obj => obj.event === 'Transfer')
          this.setState({
            account,
            network,
            environment,
            needsInit: false,
            lpAllowance,
            fundProfiles,
            allPledges,
            authorizedPayments,
            allLpEvents,
            allVaultEvents,
            transfers
          })
        }
      });
    });
  }

  appendFundProfile = async event => {
    const formattedEvent = await formatFundProfileEvent(event)
    this.setState((state) => {
      const { fundProfiles } = state
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

  transferPledgeAmounts = tx => {
    transferBetweenPledges(this.setState.bind(this), tx)
  }

  cancelFundProfile = id => {
    this.setState((state) => cancelProfile(state, id))
  }

  render() {
    const { account, needsInit, lpAllowance, fundProfiles, allPledges, authorizedPayments, transfers, allVaultEvents } = this.state
    const { appendFundProfile, appendPledges, transferPledgeAmounts, cancelFundProfile } = this
    const fundingContext = { allPledges, account, transferPledgeAmounts, authorizedPayments, cancelFundProfile, fundProfiles, needsInit, initVaultAndLP, standardTokenApproval }
    return (
      <FundingContext.Provider value={fundingContext}>
        <Router>
          <MainCointainer>
              {false &&transfers && <TransfersGraph transfers={transfers} vaultEvents={allVaultEvents} />}
              {false && !!allPledges.length && <PledgesTable data={allPledges} transferPledgeAmounts={transferPledgeAmounts} fundProfiles={fundProfiles} />}
              {false && !!fundProfiles.length && <FunderProfilesTable data={fundProfiles} cancelFundProfile={cancelFundProfile}/>}
            <AddFunder appendFundProfile={appendFundProfile} />
            <Divider variant="middle" />
            <CreateFunding refreshTable={appendPledges} />
            <Route path="/admin" component={ContractAdmin} />
          </MainCointainer>
        </Router>
      </FundingContext.Provider>
    )
  }
}

export default App
