import EmbarkJS from 'Embark/EmbarkJS'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import LiquidPledging from 'Embark/contracts/LiquidPledging'

export const getLiquidPledgingContract = () => {
  const { environment } = EmbarkJS
  if (environment === 'development') return LiquidPledgingMock
  return LiquidPledging
}
