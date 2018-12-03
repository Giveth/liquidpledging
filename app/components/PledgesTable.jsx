import React, { Fragment, PureComponent } from 'react'
import MaterialTable from 'material-table'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'
import TransferDialog from './TransferDialog'

const convertToHours = seconds => seconds / 60 / 60
const projectText = project => project === '0' ? 'N/A' : project
const formatField = field => ({
  ...field,
  commitTime: convertToHours(field.commitTime),
  amount: toEther(field.amount),
  token: getTokenLabel(field.token),
  intendedProject: projectText(field.intendedProject)
})
class PledgesTable extends PureComponent {
  state = {
    row: false,
  }

  handleClickOpen = row => {
    this.setState({ row });
  }

  handleClose = () => {
    this.setState({ row: false });
  }

  render() {
    const { data } = this.props
    const { row } = this.state
    return (
      <Fragment>
        <TransferDialog row={row} handleClose={this.handleClose} />
        <MaterialTable
          columns={[
            { title: 'Pledge Id', field: 'id', type: 'numeric' },
            { title: 'Owner', field: 'owner' },
            { title: 'Amount Funded', field: 'amount', type: 'numeric' },
            { title: 'Token', field: 'token' },
            { title: 'Commit Time', field: 'commitTime', type: 'numeric' },
            { title: 'Number of Delegates', field: 'nDelegates', type: 'numeric' },
            { title: 'Intended Project', field: 'intendedProject' },
          ]}
          data={data.map(formatField)}
          title="Pledges"
          actions={[
            {
              icon: 'compare_arrows',
              tooltip: 'Transfer funds',
              onClick: (event, rowData) => {
                this.handleClickOpen(rowData)
                console.log({event, rowData})
              }
            }
          ]}
        />
      </Fragment>
    )
  }
}

export default PledgesTable
