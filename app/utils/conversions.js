import web3 from 'Embark/web3'

export const toEther = amount => web3.utils.fromWei(amount, 'ether')
