import React from 'react'
import { FundingContext } from '../context'
import PledgesTable from './PledgesTable'
import FunderProfilesTable from './FunderProfilesTable'

const FundsManagement = ({ open }) => {
  const maxWidth = open ? `${window.visualViewport.width - 35}px` : '100vw'
  return (
    <FundingContext.Consumer>
      {({ allPledges, transferPledgeAmounts, fundProfiles, cancelFundProfile }) =>
        <div style={{ maxWidth }}>
          {!!allPledges.length && <PledgesTable data={allPledges} transferPledgeAmounts={transferPledgeAmounts} fundProfiles={fundProfiles} />}
          {!!fundProfiles.length && <FunderProfilesTable data={fundProfiles} cancelFundProfile={cancelFundProfile}/>}
        </div>
      }
    </FundingContext.Consumer>
  )
}

export default FundsManagement
