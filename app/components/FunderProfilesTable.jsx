import React, { Fragment, memo } from 'react'
import MaterialTable from 'material-table'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import { FundingContext } from '../context'

const { cancelProject } = LiquidPledgingMock.methods

const convertToHours = seconds => seconds / 60 / 60
const cancelText = canceled => canceled ? 'Yes' : 'No'
const formatField = field => ({
  ...field,
  commitTime: convertToHours(field.commitTime),
  canceled: cancelText(field.canceled)
})
const FunderProfilesTable = ({ data, cancelFundProfile }) => (
  <FundingContext.Consumer>
    {({ account }) =>
      <Fragment>
        <MaterialTable
          columns={[
            { title: 'Profile Id', field: 'idProfile', type: 'numeric' },
            { title: 'Name', field: 'name' },
            { title: 'Url', field: 'url' },
            { title: 'Admin Address', field: 'addr'},
            { title: 'Commit Time', field: 'commitTime', type: 'numeric' },
            { title: 'Type', field: 'type' },
            { title: 'Canceled', field: 'canceled' }
          ]}
          data={data.map(formatField)}
          title="Funding Profiles"
          actions={[
           rowData => ({
              icon: 'cancel',
              disabled: rowData.addr.toLowerCase() != account.toLowerCase(),
              tooltip: 'Cancel',
              onClick: (event, rowData) => {
                cancelProject(rowData.idProject || rowData.idProfile)
                  .send()
                  .then(res => {
                    console.log({res})
                    cancelFundProfile(rowData.idProfile)
                  })
              }
            })
          ]}
        />
      </Fragment>
    }
  </FundingContext.Consumer>
)

export default memo(FunderProfilesTable)
