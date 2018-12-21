import LPVault from 'Embark/contracts/LPVault'
import LiquidPledging from 'Embark/contracts/LiquidPledging'
import StandardToken from 'Embark/contracts/StandardToken'
import web3 from 'Embark/web3'

export const initVaultAndLP = async () => {
  let estimateGas;
  let toSend;


  toSend = LiquidPledging.methods.initialize(LPVault._address);
  estimateGas = await toSend.estimateGas();
  const lpInit = await toSend.send({gas: estimateGas + 1000})
  console.log(lpInit)

  toSend = LPVault.methods.initialize(LiquidPledging._address);
  estimateGas = await toSend.estimateGas();
  const vaultInit = await toSend.send({gas: estimateGas + 1000})
  console.log(vaultInit)
}

export const vaultPledgingNeedsInit = async () => {
  const needsInit = !!Number(await LiquidPledging.methods.getInitializationBlock().call())
        && !!Number(await LPVault.methods.getInitializationBlock().call())
  return needsInit
}

export const standardTokenApproval = async () => {
  const { approve } = StandardToken.methods
  const spender = LiquidPledging._address
  return await approve(
    spender,
    web3.utils.toWei('10000000', 'tether')
  ).send()
}

export const getLpAllowance = async () => {
  const { allowance } = StandardToken.methods
  const account = await web3.eth.getCoinbase()
  const spender = LiquidPledging._address
  const allowanceAmt = Number(await allowance(account, spender).call())
  return allowanceAmt
}
