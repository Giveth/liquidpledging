import { createSelector } from 'reselect'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'

export const getTransfers = state => state.allLpEvents.filter(
  obj => obj.event === 'Transfer'
)
export const getPledges = state => state.allPledges

export const getTransfersMemo = createSelector(
  getTransfers,
  transfers => transfers
)

export const getDeposits = transfers => transfers.filter(
  transfer => transfer.returnValues.from === '0'
)

const getDepositsSelector = createSelector(
  getTransfersMemo,
  getDeposits
)

export const sumDeposits = deposits => deposits.reduce(
  (pv,cv) => pv + BigInt(cv.returnValues.amount),
  BigInt(0)
).toString()

const formatAndSumDeposits = (deposits, pledges) => {
  const tokens = {}
  deposits.forEach(deposit => {
    const { amount, to } = deposit.returnValues
    const { token } = pledges.find(p => Number(p.id) === Number(to))
    const tokenName = getTokenLabel(token)
    if (tokens[tokenName]) tokens[tokenName] = BigInt(tokens[tokenName]) + BigInt(amount)
    else tokens[tokenName] = BigInt(amount)
  })
  Object
    .entries(tokens)
    .forEach(token => {
      const [key, value] = token
      tokens[key] = toEther(value.toString())
    })
  return tokens
}
export const getDepositsTotal = createSelector(
  getDepositsSelector,
  getPledges,
  formatAndSumDeposits
)
