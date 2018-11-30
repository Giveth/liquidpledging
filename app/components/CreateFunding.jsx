import React from 'react';
import { Formik } from 'formik';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Snackbar from '@material-ui/core/Snackbar';
import MenuItem from '@material-ui/core/MenuItem';
import web3 from 'Embark/web3';
import { MySnackbarContentWrapper } from './base/SnackBars';
import { currencies, TOKEN_ICON_API } from '../utils/currencies'

const { addGiver } = LiquidPledgingMock.methods
const hoursToSeconds = hours => hours * 60 * 60
const addFunderSucessMsg = response => {
  const { events: { GiverAdded: { returnValues: { idGiver } } } } = response
  return `Funder created with ID of ${idGiver}`
}

const CreateFunding = () => (
  <Formik
    initialValues={{ funderId: '', receiverId: '', tokenAddress : '' }}
    onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
      const { funderId, receiverId, tokenAddress } = values
      const account = await web3.eth.getCoinbase()
      const args = [funderId, receiverId, tokenAddress, 0]
      addGiver(...args)
        .estimateGas({ from: account })
        .then(async gas => {
          addGiver(...args)
            .send({ from: account, gas: gas + 100 })
            .then(res => {
              console.log({res})
              setStatus({
                snackbar: { variant: 'success', message: addFunderSucessMsg(res) }
              })
            })
            .catch(e => {
              console.log({e})
              setStatus({
                snackbar: { variant: 'error', message: 'There was an error' }
              })
            })
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
       setFieldValue,
       setStatus,
       status
    }) => (
      <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column' }}>
        <TextField
          id="funderId"
          name="funderId"
          label="Funder Id"
          placeholder="Funder Id"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.funderId || ''}
        />
        <TextField
          id="receiverId"
          name="receiverId"
          label="Receiver Id"
          placeholder="Receiver Id"
          margin="normal"
          variant="outlined"
          helperText="The receiver of the funding can be any admin, giver, delegate or a project"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.receiverId || ''}
        />
        <TextField
          id="tokenAddress"
          name="tokenAddress"
          select
          label="Select token for funding"
          placeholder="Select token for funding"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.tokenAddress || ''}
        >
          {currencies.map(option => (
            <MenuItem style={{ display: 'flex', alignItems: 'center' }} key={option.value} value={option.value}>
              <img
                src={option.img || `${TOKEN_ICON_API}/${option.value}.png`}
                style={{ width: '3%', marginRight: '3%' }}
              />
              {option.label}
            </MenuItem>
          ))}
        </TextField>
        {/* TODO ADD Amount TextField */}
        <Button variant="contained" color="primary" type="submit">
          PROVIDE FUNDING
        </Button>
        {status && <Snackbar
                     anchorOrigin={{
                       vertical: 'bottom',
                       horizontal: 'left',
                     }}
                     open={!!status.snackbar}
                     autoHideDuration={6000}
                     onClose={() => setStatus(null)}
                   >
          <MySnackbarContentWrapper
            onClose={() => setStatus(null)}
            variant={status.snackbar.variant}
            message={status.snackbar.message}
          />
        </Snackbar>}
      </form>
    )}
  </Formik>
)

export default CreateFunding
