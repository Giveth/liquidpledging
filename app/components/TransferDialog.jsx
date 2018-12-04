import React from 'react'
import { Formik } from 'formik'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import Button from '@material-ui/core/Button'
import TextField from '@material-ui/core/TextField'
import Dialog from '@material-ui/core/Dialog'
import DialogActions from '@material-ui/core/DialogActions'
import DialogContent from '@material-ui/core/DialogContent'
import DialogContentText from '@material-ui/core/DialogContentText'
import DialogTitle from '@material-ui/core/DialogTitle'
import { getTokenLabel } from '../utils/currencies'
import { toWei } from '../utils/conversions'

const { transfer } = LiquidPledgingMock.methods

const TransferDialog = ({ row, handleClose }) => (
  <Formik
    initialValues={{}}
    onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
      const { owner, id } = row
      const { amount, idReceiver } = values
      const args = [owner, id, toWei(amount.toString()), idReceiver]
      transfer(...args)
        .send()
        .then(res => {
          console.log({res})
          handleClose()

        })
        .catch(e => {
          console.log({e})
        })
    }}
  >
    {({
       values,
       errors,
       touched,
       handleChange,
       handleBlur,
       handleSubmit,
       submitForm,
       setFieldValue,
       setStatus,
       status
    }) => (
      <form onSubmit={handleSubmit}>
        <Dialog
          open={!!row}
          onClose={handleClose}
          aria-labelledby="form-dialog-title"
        >
          <DialogTitle id="form-dialog-title">Transfer Funds</DialogTitle>
          <DialogContent>
            <DialogContentText>
              {`Transfer ${values.amount || ''}  ${values.amount ? getTokenLabel(row[6]) : ''} from Pledge ${row.id} ${values.idReceiver ? 'to Giver/Delegate/Project' : ''} ${values.idReceiver || ''}`}
            </DialogContentText>
            <TextField
              autoFocus
              margin="normal"
              id="amount"
              name="amount"
              label="Amount to transfer"
              placeholder="Amount to transfer"
              variant="outlined"
              type="number"
              autoComplete="off"
              fullWidth
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.amount || ''}
            />
            <TextField
              margin="normal"
              id="idReceiver"
              name="idReceiver"
              label="Receiver of funds"
              placeholder="Receiver of funds"
              variant="outlined"
              helperText="Destination of the amount, can be a Giver/Project sending to a Giver, a Delegate or a Project; a Delegate sending to another Delegate, or a Delegate pre-commiting it to a Project"
              autoComplete="off"
              fullWidth
              onChange={handleChange}
              onBlur={handleBlur}
              value={values.idReceiver || ''}
            />
          </DialogContent>
          <DialogActions>
            <Button onClick={handleClose} color="primary">
              Cancel
            </Button>
            <Button onClick={submitForm} color="primary" type="submit">
              Transfer
            </Button>
          </DialogActions>
        </Dialog>
      </form>
    )}
  </Formik>
)

export default TransferDialog
