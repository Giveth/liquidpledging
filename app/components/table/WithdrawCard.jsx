import React, { PureComponent } from 'react'
import PropTypes from 'prop-types'
import { Formik } from 'formik'
import { withStyles } from '@material-ui/core/styles'
import Card from '@material-ui/core/Card'
import CardActions from '@material-ui/core/CardActions'
import CardContent from '@material-ui/core/CardContent'
import Button from '@material-ui/core/Button'
import Typography from '@material-ui/core/Typography'
import TextField from '@material-ui/core/TextField'
import indigo from '@material-ui/core/colors/indigo'
import blueGrey from '@material-ui/core/colors/blueGrey'
import Collapse from '@material-ui/core/Collapse'
import LiquidPledgingMock from 'Embark/contracts/LiquidPledgingMock'
import LPVault from 'Embark/contracts/LPVault'
import { getTokenLabel } from '../../utils/currencies'
import { toWei } from '../../utils/conversions'
import { FundingContext } from '../../context'

const { withdraw } = LiquidPledgingMock.methods
const { confirmPayment } = LPVault.methods

const styles = {
  card: {
    borderRadius: '0px',
    borderTopStyle: 'groove',
    borderBottom: '1px solid lightgray',
    backgroundColor: indigo[50]
  },
  bullet: {
    display: 'inline-block',
    margin: '0 2px',
    transform: 'scale(0.8)',
  },
  title: {
    fontSize: 14,
  },
  amount: {
    backgroundColor: blueGrey[50]
  }
}

class Withdraw extends PureComponent {
  state = { show: null }

  componentDidMount() {
    this.setState({ show: true })
  }

  close = () => {
    this.setState(
      { show: false },
      () => setTimeout(() => { this.props.clearRowData() }, 500)
    )
  }

  render() {
    const { classes, rowData } = this.props
    const { show } = this.state
    const isPaying = rowData[7] === "1"
    return (
      <FundingContext.Consumer>
      {({ authorizedPayments }) =>
      <Formik
        initialValues={{}}
        onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
          const { amount } = values
          const paymentId = isPaying ? authorizedPayments.find(r => r.ref === rowData.id)['idPayment'] : rowData.id
          const args = isPaying ? [paymentId] : [paymentId, toWei(amount)]
          const sendFn = isPaying ? confirmPayment : withdraw
          try {
            const toSend = sendFn(...args);
            const estimateGas = await toSend.estimateGas();
            toSend.send({ gas: estimateGas + 1000 })
                  .then(res => {
                    console.log({res})
                  })
                  .catch(e => {
                    console.log({e})
                  })
                  .finally(() => {
                    this.close()
                  })
          } catch (error) {
            console.log(error)
          }
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
          <Collapse in={show}>
            <form autoComplete="off" onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', marginBottom: '0px' }}>
              <Card className={classes.card} elevation={0}>
                <CardContent>
                  <Typography variant="h6" component="h2">
                    {`${isPaying ? 'Confirm' : ''} Withdraw${isPaying ? 'al' : ''} ${values.amount || ''}  ${values.amount ? getTokenLabel(rowData[6]) : ''} from Pledge ${rowData.id}`}
                  </Typography>
                  {!isPaying && <TextField
                    className={classes.amount}
                    id="amount"
                    name="amount"
                    label="Amount"
                    placeholder="Amount"
                    margin="normal"
                    variant="outlined"
                    onChange={handleChange}
                    onBlur={handleBlur}
                    value={values.amount || ''}
                  />}
                </CardContent>
                <CardActions>
                  <Button size="large" onClick={this.close}>Cancel</Button>
                  <Button size="large" color="primary" type="submit">{isPaying ? 'Confirm' : 'Withdraw'}</Button>
                </CardActions>
              </Card>
            </form>
          </Collapse>
        )}
      </Formik>
      }
      </FundingContext.Consumer>
    )
  }
}

Withdraw.propTypes = {
  classes: PropTypes.object.isRequired,
  rowData: PropTypes.object.isRequired
}

export default withStyles(styles)(Withdraw)
