import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'

const { getPledgeAdmin, numberOfPledges, getPledge } = LiquidPledgingMock.methods
export const formatPledge = async (pledgePromise, idx) => {
  const pledge = await pledgePromise
  return {
    ...pledge,
    id: idx + 1
  }
}

export const getAllPledges = async (start = 1) => {
  const numPledges = await LiquidPledgingMock.methods.numberOfPledges().call()
  const pledges = []
  for (let i = start; i <= numPledges; i++) {
    pledges.push(getPledge(i).call())
  }
   return Promise.all(pledges.map(formatPledge))
}

export const appendToExistingPledges = async (pledges, setState) => {
  const numPledges = await numberOfPledges().call()
  const difference = numPledges - pledges.length
  if (difference > 0) {
    const newPledges = await getAllPledges(difference)
    setState((state) => ({
      ...state,
      allPledges: {
        ...state.allPledges,
        ...newPledges
      }
    }))
  }
}

export const transferBetweenPledges = (setState, tx) => {
  const { from, to, amount } = tx
  setState((state) => {
    const { allPledges } = state;
    const updatedPledges = allPledges.map(pledge => {
      if (pledge.id === Number(from)) {
        pledge.amount = (BigInt(pledge.amount) - BigInt(amount)).toString()
        return pledge
      }
      if (pledge.id === Number(to)) {
        pledge.amount = (BigInt(pledge.amount) + BigInt(amount)).toString()
        return pledge
      }
      return pledge
    })
    console.log({updatedPledges, tx})
    return {
      ...state,
      allPledges: [ ...updatedPledges ]
    }
  })
}
