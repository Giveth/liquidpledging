import React from 'react'
import Button from '@material-ui/core/Button'
import TextField from '@material-ui/core/TextField'
import Dialog from '@material-ui/core/Dialog'
import DialogActions from '@material-ui/core/DialogActions'
import DialogContent from '@material-ui/core/DialogContent'
import DialogContentText from '@material-ui/core/DialogContentText'
import DialogTitle from '@material-ui/core/DialogTitle'

const TransferDialog = ({ row, handleClose }) => {
  return (
    <div>
      <Dialog
        open={!!row}
        onClose={handleClose}
        aria-labelledby="form-dialog-title"
      >
        <DialogTitle id="form-dialog-title">{`Transfer Funds from Pledge ${row.id}`}</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Transfer funds between pledges
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
          />
          <TextField
            autoFocus
            margin="normal"
            id="idReceiver"
            name="idReceiver"
            label="Receiver of funds"
            placeholder="Receiver of funds"
            variant="outlined"
            helperText="Destination of the amount, can be a Giver/Project sending to a Giver, a Delegate or a Project; a Delegate sending to another Delegate, or a Delegate pre-commiting it to a Project"
            autoComplete="off"
            fullWidth
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} color="primary">
            Cancel
          </Button>
          <Button onClick={handleClose} color="primary">
            Subscribe
          </Button>
        </DialogActions>
      </Dialog>
    </div>
  )
}

export default TransferDialog
