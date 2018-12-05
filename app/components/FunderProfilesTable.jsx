import React, { Fragment, memo } from 'react'
import MaterialTable from 'material-table'

const convertToHours = seconds => seconds / 60 / 60
const cancelText = canceled => canceled ? 'Yes' : 'No'
const formatField = field => ({
  ...field,
  commitTime: convertToHours(field.commitTime),
  canceled: cancelText(field.canceled)
})
const FunderProfilesTable = ({ data }) => (
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
    />
  </Fragment>
)

export default memo(FunderProfilesTable)
