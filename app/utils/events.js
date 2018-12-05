import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import web3 from 'Embark/web3'

const GIVER_ADDED = 'GiverAdded'
const DELEGATE_ADDED = 'DelegateAdded'
const PROJECT_ADDED = 'ProjectAdded'
const lookups = {
  [GIVER_ADDED]: {
    id: 'idGiver',
    type: 'Funder'
  },
  [DELEGATE_ADDED]: {
    id: 'idDelegate',
    type: 'Delegate'
  },
  [PROJECT_ADDED]: {
    id: 'idProject',
    type: 'Project'
  }
}

const { getPledgeAdmin } = LiquidPledgingMock.methods
export const formatFundProfileEvent = async event => {
  const lookup = lookups[event.event]
  const { returnValues: { url } } = event
  const idProfile = event.returnValues[lookup.id]
  const { addr, commitTime, name, canceled } = await getPledgeAdmin(idProfile).call()
  return {
    idProfile,
    url,
    commitTime,
    name,
    addr,
    canceled,
    type: lookups[event.event].type
  }
}

const getPastEvents = async event => {
  const events = await LiquidPledgingMock.getPastEvents(event, {
    addr: await web3.eth.getCoinbase(),
    fromBlock: 0,
    toBlock: 'latest'
  })
  const formattedEvents = await Promise.all(
    events.map(formatFundProfileEvent)
  )
  return formattedEvents
}
export const getFunderProfiles = async () => await getPastEvents(GIVER_ADDED)
export const getDelegateProfiles = async () => await getPastEvents(DELEGATE_ADDED)
export const getProjectProfiles = async () => await getPastEvents(PROJECT_ADDED)
export const getProfileEvents = async () => {
  const [ funderProfiles, delegateProfiles, projectProfiles]
        = await Promise.all([getFunderProfiles(), getDelegateProfiles(), getProjectProfiles()])
  return [ ...funderProfiles, ...delegateProfiles, ...projectProfiles]
}
