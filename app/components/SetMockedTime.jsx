import React from 'react'
import { Formik } from 'formik'
import LiquidPledging from 'Embark/contracts/LiquidPledging'
import TextField from '@material-ui/core/TextField'

const { setMockedTime } = LiquidPledging.methods

const SetMockedTime = () => (
  <Formik
  initialValues={{}}
  onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
      const { time } = values
      const n = Math.floor(new Date().getTime() / 1000) + Number(time)
      setMockedTime(n)
                    .send()
                    .then(res => {console.log({res})})
                    .catch(err => {console.log({err})})
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
          autoComplete="off"
          id="time"
          name="time"
          label="Set Mocked Time in seconds"
          placeholder="Set Mocked Time in seconds"
          margin="normal"
          variant="outlined"
          onChange={handleChange}
          onBlur={handleBlur}
          value={values.time || ''}
        />
      </form>
    )}
  </Formik>
)

export default SetMockedTime
