import React, { Fragment, PureComponent } from 'react'
import MaterialTable from 'material-table'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'
import TransferDialog from './TransferDialog'
import WithdrawCard from './table/WithdrawCard'

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

  clearRowData = () => this.setState({ rowData: null })

  render() {
    const { data, transferPledgeAmounts } = this.props
    const { row, rowData } = this.state
    return (
      <Fragment>
        <TransferDialog
          row={row}
          handleClose={this.handleClose}
          transferPledgeAmounts={transferPledgeAmounts}
        />
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
              }
            },
            {
              icon: 'attach_money',
              tooltip: 'Request Withdrawl',
              onClick: (event, rowData) => {
                console.log({rowData})
                this.setState({ rowData })
              }
            }
          ]}
        />
        {rowData && <WithdrawCard  rowData={rowData} clearRowData={this.clearRowData} />}
      </Fragment>
    )
  }
}

export default PledgesTable
