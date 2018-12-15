import React, { Fragment } from 'react'
import Button from '@material-ui/core/Button'
import { FundingContext } from '../context'
import SetMockedTime from './SetMockedTime'

const ContractAdmin = () => (
  <FundingContext.Consumer>
  {({ needsInit, initVaultAndLP, standardTokenApproval }) =>
    <Fragment>
      {needsInit && <Button variant="outlined" color="secondary" onClick={initVaultAndLP}>
        Initialize Contracts
      </Button>}
      <Button variant="outlined" color="primary" onClick={standardTokenApproval}>
        GIVE VAULT TOKEN APPROVAL
      </Button>
      <SetMockedTime />
    </Fragment>
  }
  </FundingContext.Consumer>
)

export default ContractAdmin
