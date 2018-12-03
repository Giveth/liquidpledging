import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import web3 from 'Embark/web3'

const GIVER_ADDED = 'GiverAdded'
const DELEGATE_ADDED = 'DelegateAdded'
const lookups = {
  [GIVER_ADDED]: {
    id: 'idGiver',
    type: 'Funder'
  },
  [DELEGATE_ADDED]: {
    id: 'idDelegate',
    type: 'Delegate'
  }
}

const { getPledgeAdmin } = LiquidPledgingMock.methods
export const formatFundProfileEvent = async event => {
  const lookup = lookups[event.event]
  const { returnValues: { url } } = event
  const idProfile = event.returnValues[lookup.id]
  const { commitTime, name, canceled } = await getPledgeAdmin(idProfile).call()
  return {
    idProfile,
    url,
    commitTime,
    name,
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
export const getFunderProfiles = async () => await getPastEvents('GiverAdded')
export const getDelegateProfiles = async () => await getPastEvents('DelegateAdded')
export const getProfileEvents = async () => {
  const funderProfiles = await getFunderProfiles()
  const delegateProfiles = await getDelegateProfiles()
  return [ ...funderProfiles, ...delegateProfiles]
}
