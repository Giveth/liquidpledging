import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import web3 from 'Embark/web3'

const { getPledgeAdmin } = LiquidPledgingMock.methods
const formatFundProfileEvent = async event => {
  const { returnValues: { idGiver, url } } = event
  const { commitTime, name, canceled } = await getPledgeAdmin(idGiver).call()
  return {
    idGiver,
    url,
    commitTime,
    name,
    canceled
  }
}

export const getUserFundProfiles = async () => {
  const events = await LiquidPledgingMock.getPastEvents('GiverAdded', {
    addr: await web3.eth.getCoinbase(),
    fromBlock: 0,
    toBlock: 'latest'
  })
  const formattedEvents = await Promise.all(events.map(formatFundProfileEvent))
  return formattedEvents
}
