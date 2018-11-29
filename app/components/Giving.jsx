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
const createGiver = async (name, url, commitTime) => {
}

const Giving = () => (
  <Formik
  initialValues={{ giverName: '', giverProfile: '', commitTime : '' }}
  onSubmit={async (values, { setSubmitting, resetForm }) => {
    const { giverName, giverProfile, commitTime } = values;
    const account = await web3.eth.getCoinbase();
    const args = [giverName, giverProfile, commitTime, 0];
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
        id="giverName"
        name="giverName"
        label="Giver Name"
        placeholder="Giver Name"
        margin="normal"
        variant="outlined"
        onChange={handleChange}
        onBlur={handleBlur}
        value={values.giverName || ''}
      />
      <TextField
        id="giverProfile"
        name="giverProfile"
        label="Giver Profile URL or IPFS Hash"
        placeholder="Giver Profile URL or IPFS Hash"
        margin="normal"
        variant="outlined"
        onChange={handleChange}
        onBlur={handleBlur}
        value={values.giverProfile || ''}
      />
      <TextField
        id="commitTime"
        name="commitTime"
        label="Commit time in hours"
        placeholder="Commit time in hours"
        margin="normal"
        variant="outlined"
        helperText="The length of time in hours the Giver has to veto when the delegates pledge funds to a project"
        onChange={handleChange}
        onBlur={handleBlur}
        value={values.commitTime || ''}
      />
      <Button variant="contained" color="primary" type="submit">
        ADD GIVER
      </Button>
    </form>
  )}
      </Formik>
)

export default Giving;
