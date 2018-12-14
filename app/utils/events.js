import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import LPVault from 'Embark/contracts/LPVault'
import web3 from 'Embark/web3'

const AUTHORIZE_PAYMENT = 'AuthorizePayment'
const GIVER_ADDED = 'GiverAdded'
const DELEGATE_ADDED = 'DelegateAdded'
const PROJECT_ADDED = 'ProjectAdded'
const ALL_EVENTS = 'allEvents'
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

const formatVaultEvent = async event => {
  const { returnValues } = event
  return {
    ...returnValues,
    ref: Number(returnValues.ref.slice(2))
  }
}

const getPastVaultEvents = async event => {
  const events = await LPVault.getPastEvents(event, {
    addr: await web3.eth.getCoinbase(),
    fromBlock: 0,
    toBlock: 'latest'
  })
  const formattedEvents = await Promise.all(
    events.map(formatVaultEvent)
  )
  return formattedEvents
}

const { getPledgeAdmin } = LiquidPledgingMock.methods
export const formatFundProfileEvent = async event => {
  const lookup = lookups[event.event]
  const { returnValues: { url, idProject } } = event
  const idProfile = event.returnValues[lookup.id]
  const { addr, commitTime, name, canceled } = await getPledgeAdmin(idProfile).call()
  return {
    idProfile,
    idProject,
    url,
    commitTime,
    name,
    addr,
    canceled,
    type: lookups[event.event].type
  }
}

const getPastEvents = async (event, raw = false) => {
  const events = await LiquidPledgingMock.getPastEvents(event, {
    addr: await web3.eth.getCoinbase(),
    fromBlock: 0,
    toBlock: 'latest'
  })
  if (raw) return events
  const formattedEvents = await Promise.all(
    events.map(formatFundProfileEvent)
  )
  return formattedEvents
}

export const lpEventsSubscription = async () => {
  //todo add on event handlers
  const events = await LiquidPledgingMock.events.allEvents({
    fromBlock: 0,
    toBlock: 'latest'
  })
  return events
}
export const getFunderProfiles = async () => await getPastEvents(GIVER_ADDED)
export const getDelegateProfiles = async () => await getPastEvents(DELEGATE_ADDED)
export const getProjectProfiles = async () => await getPastEvents(PROJECT_ADDED)
export const getAllLPEvents = async () => await getPastEvents(ALL_EVENTS, true)
export const getAuthorizedPayments = async () => getPastVaultEvents(AUTHORIZE_PAYMENT)
export const getProfileEvents = async () => {
  const [ funderProfiles, delegateProfiles, projectProfiles]
        = await Promise.all([getFunderProfiles(), getDelegateProfiles(), getProjectProfiles()])
  return [ ...funderProfiles, ...delegateProfiles, ...projectProfiles]
}
