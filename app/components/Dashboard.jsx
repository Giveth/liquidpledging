import React from 'react'
import PledgeAllocationsChart from './dashboard/PledgeAllocationsChart'
import FundingSummary from './dashboard/FundingSummary'

const Dashboard = () => (
  <div>
    <FundingSummary title="Funding Summary" />
    <PledgeAllocationsChart title="Pledge Allocations" />
  </div>
)

export default Dashboard
