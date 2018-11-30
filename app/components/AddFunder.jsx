import React from 'react';
import { Formik } from 'formik';
import EmbarkJS from 'Embark/EmbarkJS';
import LPVault from 'Embark/contracts/LPVault';
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock';
import Button from '@material-ui/core/Button';
import TextField from '@material-ui/core/TextField';
import web3 from "Embark/web3";

const { addGiver, numberOfPledgeAdmins, getPledgeAdmin } = LiquidPledgingMock.methods;
const hoursToSeconds = hours => hours * 60 * 60;

const AddFunder = () => (
  <Formik
  initialValues={{ funderName: '', funderProfile: '', commitTime : '' }}
  onSubmit={async (values, { setSubmitting, resetForm }) => {
    const { funderName, funderProfile, commitTime } = values;
    const account = await web3.eth.getCoinbase();
    const args = [funderName, funderProfile, commitTime, 0];
    addGiver(...args)
      .estimateGas({ from: account })
      .then(async gas => {
        addGiver(...args)
        .send({ from: account, gas: gas + 100 })
        .then(res => { console.log({res}) })
        .catch(e => { console.log({e}) })
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
    setFieldValue
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
    </form>
  )}
      </Formik>
)

export default AddFunder;
