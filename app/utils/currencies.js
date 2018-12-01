import StandardToken from 'Embark/contracts/StandardToken'

export const TOKEN_ICON_API = 'https://raw.githubusercontent.com/TrustWallet/tokens/master/images'
export const TOKEN_COIN_API = 'https://raw.githubusercontent.com/TrustWallet/tokens/master/coins'
export const currencies = [
  {
    value: 'ETH',
    label: 'Ether',
    img: `${TOKEN_COIN_API}/60.png`,
  },
  {
    value: '0x744d70fdbe2ba4cf95131626614a1763df805b9e',
    label: 'Status (SNT)',
  },
  {
    value: '0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359',
    label: 'DAI',
  },
  {
    value: StandardToken._address,
    label: 'Standard Token',
    icon: '🤔',
  }
]

export const getTokenLabel = value => {
  const token = currencies.find(currency => currency.value === value)
  return token ? token.label : null
}
