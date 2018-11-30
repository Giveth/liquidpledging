import React from 'react';
import { Formik } from 'formik';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import Snackbar from '@material-ui/core/Snackbar';
import web3 from "Embark/web3";
import { MySnackbarContentWrapper } from './base/SnackBars';

const { addGiver, numberOfPledgeAdmins, getPledgeAdmin } = LiquidPledgingMock.methods;
const hoursToSeconds = hours => hours * 60 * 60;
const addFunderSucessMsg = response => {
  const { events: { GiverAdded: { returnValues: { idGiver } } } } = response;
  return `Funder created with ID of ${idGiver}`;
}

const AddFunder = () => (
  <Formik
    initialValues={{ funderName: '', funderProfile: '', commitTime : '' }}
    onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
      const { funderName, funderProfile, commitTime } = values;
      const account = await web3.eth.getCoinbase();
      const args = [funderName, funderProfile, commitTime, 0];
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
          id="funderName"
          name="funderName"
          label="Funder Name"
          placeholder="Funder Name"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.funderName || ''}
        />
        <TextField
          id="funderProfile"
          name="funderProfile"
          label="Funder Profile URL or IPFS Hash"
          placeholder="Funder Profile URL or IPFS Hash"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.funderProfile || ''}
        />
        <TextField
          id="commitTime"
          name="commitTime"
          label="Commit time in hours"
          placeholder="Commit time in hours"
          margin="normal"
          variant="outlined"
          helperText="The length of time in hours the Funder has to veto when the delegates pledge funds to a project"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.commitTime || ''}
        />
        <Button variant="contained" color="primary" type="submit">
          ADD FUNDER
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

export default AddFunder;
