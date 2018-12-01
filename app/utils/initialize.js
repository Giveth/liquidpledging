import LPVault from 'Embark/contracts/LPVault'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import StandardToken from 'Embark/contracts/StandardToken'
import web3 from "Embark/web3"

export const initVaultAndLP = async () => {
  const vaultInit = await LPVault.methods.initialize(LiquidPledgingMock._address).send()
  console.log(vaultInit)
  const lpInit = await LiquidPledgingMock.methods.initialize(LPVault._address).send()
  console.log(lpInit)
}

export const vaultPledgingNeedsInit = async () => {
  const needsInit = Number(await LiquidPledgingMock.methods.getInitializationBlock().call())
        + Number(await LPVault.methods.getInitializationBlock().call())
  return needsInit
}

export const standardTokenApproval = async () => {
  const { approve } = StandardToken.methods
  const spender = LiquidPledgingMock._address
  return await approve(
    spender,
    web3.utils.toWei('10000000', 'tether')
  ).send()
}

export const getLpAllowance = async () => {
  const { allowance } = StandardToken.methods
  const account = await web3.eth.getCoinbase()
  const spender = LiquidPledgingMock._address
  const allowanceAmt = Number(await allowance(account, spender).call())
  return allowanceAmt
}
