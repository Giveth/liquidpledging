import LPVault from 'Embark/contracts/LPVault'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import StandardToken from 'Embark/contracts/StandardToken'
import web3 from "Embark/web3"

export const initVaultAndLP = async (lp, vault) => {
  const vaultInit = await vault.methods.initialize(lp._address).send()
  console.log(vaultInit)
  const lpInit = await lp.methods.initialize(vault._address).send()
  console.log(lpInit)
}

export const vaultPledgingNeedsInit = async () => {
  const needsInit = Number(await LiquidPledgingMock.methods.getInitializationBlock().call())
        + Number(await LPVault.methods.getInitializationBlock().call())
  return needsInit
}

export const standardTokenApproval = async () => {
  const { approve, allowance } = StandardToken.methods
  const account = await web3.eth.getCoinbase()
  const spender = LiquidPledgingMock._address
  const allowanceAmt = Number(await allowance(account, spender).call())
  if (allowanceAmt < 1000) {
    return await approve(
      spender,
      web3.utils.toWei('10000000', 'tether')
    ).send()
  }
}
