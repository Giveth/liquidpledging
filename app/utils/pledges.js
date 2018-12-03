import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'

// amount: "21000000000000000000"
// commitTime: "0"
// intendedProject: "0"
// nDelegates: "1"
// oldPledge: "0"
// owner: "4"
// pledgeState: "0"
// token: "0x10Aa1c9C2ad79b240Dc612cd2c0c0f5513bAfF28"

const { getPledgeAdmin, numberOfPledges, getPledge } = LiquidPledgingMock.methods
export const formatPledge = async (pledgePromise, idx) => {
  const pledge = await pledgePromise
  return {
    ...pledge,
    id: idx
  }
}

export const getAllPledges = async () => {
  const numPledges = await numberOfPledges().call()
  const pledges = []
  for (let i = 0; i <= numPledges; i++) {
    pledges.push(getPledge(i).call())
  }
  return Promise.all(pledges.map(formatPledge))
}
