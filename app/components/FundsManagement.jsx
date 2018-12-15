import React from 'react'
import Divider from '@material-ui/core/Divider'
import { FundingContext } from '../context'
import PledgesTable from './PledgesTable'
import FunderProfilesTable from './FunderProfilesTable'
import AddFunder from './AddFunder'
import CreateFunding from './CreateFunding'

const FundsManagement = ({ open }) => {
  const maxWidth = open ? `${window.visualViewport.width - 35}px` : '100vw'
  return (
    <FundingContext.Consumer>
      {({ allPledges, appendPledges, appendFundProfile, transferPledgeAmounts, fundProfiles, cancelFundProfile }) =>
        <div style={{ maxWidth }}>
          {!!allPledges.length && <PledgesTable data={allPledges} transferPledgeAmounts={transferPledgeAmounts} fundProfiles={fundProfiles} />}
          {!!fundProfiles.length && <FunderProfilesTable data={fundProfiles} cancelFundProfile={cancelFundProfile}/>}
          <AddFunder appendFundProfile={appendFundProfile} />
          <Divider variant="middle" />
          <CreateFunding refreshTable={appendPledges} />
        </div>
      }
    </FundingContext.Consumer>
  )
}

export default FundsManagement
