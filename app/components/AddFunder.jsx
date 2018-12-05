import React from 'react'
import { Formik } from 'formik'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import Button from '@material-ui/core/Button'
import MenuItem from '@material-ui/core/MenuItem'
import TextField from '@material-ui/core/TextField'
import Snackbar from '@material-ui/core/Snackbar'
import web3 from 'Embark/web3'
import { MySnackbarContentWrapper } from './base/SnackBars'

const { addGiver, addDelegate, addProject } = LiquidPledgingMock.methods
const FUNDER = 'FUNDER'
const DELEGATE = 'DELEGATE'
const PROJECT = 'PROJECT'
const helperText = {
  [FUNDER]: 'The length of time in hours the Funder has to veto when the delegates pledge funds to a project',
  [DELEGATE]: 'The length of time in hours the Delegate can be vetoed. Whenever this delegate is in a delegate chain the time allowed to veto any event must be greater than or equal to this time',
  [PROJECT]: 'The length of time the Project has to veto when the project delegates to another delegate and they pledge those funds to a project'
}
const funderNameLabel = {
  [FUNDER]: 'Funding',
  [DELEGATE]: 'Delegate',
  [PROJECT]: 'Project'
}
const buttonLabel = {
  [FUNDER]: 'FUNDING',
  [DELEGATE]: 'DELEGATE',
  [PROJECT]: 'PROJECT'
}
const sendFns = {
  [FUNDER]: addGiver,
  [DELEGATE]: addDelegate,
  [PROJECT]: addProject
}
const adminProfiles = [FUNDER, DELEGATE, PROJECT]
const hoursToSeconds = hours => hours * 60 * 60
const addFunderSucessMsg = response => {
  const { events: { GiverAdded: { returnValues: { idGiver } } } } = response
  return `Funder created with ID of ${idGiver}`
}
const addDelegateSucessMsg = response => {
  const { events: { DelegateAdded: { returnValues: { idDelegate } } } } = response
  return `Delegate created with ID of ${idDelegate}`
}
const addProjectSucessMsg = response => {
  const { events: { DelegateAdded: { returnValues: { idProject } } } } = response
  return `Project created with ID of ${idProject}`
}
const successMsg = {
  [FUNDER]: addFunderSucessMsg,
  [DELEGATE]: addDelegateSucessMsg,
  [PROJECT]: addProjectSucessMsg
}

const AddFunder = ({ appendFundProfile }) => (
  <Formik
    initialValues={{ adminType: FUNDER, funderName: '', funderDescription: '', commitTime : '' }}
    onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
      const { adminType, funderName, funderDescription, commitTime } = values
      const account = await web3.eth.getCoinbase()
      //TODO add field for parent project
      const args = adminType === PROJECT
                 ? [funderName, funderDescription, account, 0, hoursToSeconds(commitTime), 0]
                 : [funderName, funderDescription, hoursToSeconds(commitTime), 0]
      const isFunder = adminType === FUNDER
      const sendFn = sendFns[adminType]
      sendFn(...args)
        .estimateGas({ from: account })
        .then(async gas => {
          sendFn(...args)
            .send({ from: account, gas: gas + 100 })
            .then(res => {
              console.log({res})
              if (isFunder) appendFundProfile(res.events.GiverAdded)
              setStatus({
                snackbar: {
                  variant: 'success',
                  message: successMsg[adminType](res)
                }
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
          id="adminType"
          name="adminType"
          select
          label="Select admin type"
          placeholder="Select admin type"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.adminType || ''}
        >
          {adminProfiles.map(profile => (
            <MenuItem style={{ display: 'flex', alignItems: 'center' }} key={profile} value={profile}>
              {profile}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          id="funderName"
          name="funderName"
          label={`${funderNameLabel[values.adminType]} Name`}
          placeholder={`${funderNameLabel[values.adminType]} Name`}
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.funderName || ''}
        />
        <TextField
          id="funderDescription"
          name="funderDescription"
          label="Description (URL or IPFS Hash)"
          placeholder="Description (URL or IPFS Hash)"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.funderDescription || ''}
        />
        <TextField
          id="commitTime"
          name="commitTime"
          label="Commit time in hours"
          placeholder="Commit time in hours"
          margin="normal"
          variant="outlined"
          helperText={helperText[values.adminType]}
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.commitTime || ''}
        />
        <Button variant="contained" color="primary" type="submit">
          {`ADD ${buttonLabel[values.adminType]} PROFILE`}
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

export default AddFunder
