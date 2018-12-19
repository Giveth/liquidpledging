import { createSelector } from 'reselect'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'

export const getTransfers = state => state.allLpEvents.filter(
  obj => obj.event === 'Transfer'
)
const getWithdraws = state => state.vaultEvents.filter(
  event => event.event === 'AuthorizePayment'
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

const formatAndSumDepositWithdraws = (deposits, pledges, withdraws) => {
  const tokens = {}
  deposits.forEach(deposit => {
    const { amount, to } = deposit.returnValues
    const { token } = pledges.find(p => Number(p.id) === Number(to))
    const tokenName = getTokenLabel(token)
    if (tokens[tokenName]) tokens[tokenName]['deposits'] = BigInt(tokens[tokenName]['deposits']) + BigInt(amount)
    else tokens[tokenName] = { 'deposits': BigInt(amount) }
  })

  withdraws
    .filter(w => !isNaN(Number(w.returnValues.ref.slice(2))))
    .forEach(withdraw => {
      const { returnValues: { amount, token } } = withdraw
      const tokenName = getTokenLabel(token)
      if (tokens[tokenName]['withdraws']) tokens[tokenName]['withdraws'] = BigInt(tokens[tokenName]['withdraws']) + BigInt(amount)
      else tokens[tokenName]['withdraws'] = BigInt(amount)
    })

  Object
    .entries(tokens)
    .forEach(token => {
      const [key, value] = token
      tokens[key]['deposits'] = toEther(value['deposits'].toString())
      if (tokens[key]['withdraws']) tokens[key]['withdraws'] = toEther(value['withdraws'].toString())
    })
  return tokens
}
export const getDepositWithdrawTotals = createSelector(
  getDepositsSelector,
  getPledges,
  getWithdraws,
  formatAndSumDepositWithdraws
)
