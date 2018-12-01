export const initVaultAndLP = async (lp, vault) => {
  const vaultInit = await vault.methods.initialize(lp._address).send()
  console.log(vaultInit)
  const lpInit = await lp.methods.initialize(vault._address).send()
  console.log(lpInit)
}
