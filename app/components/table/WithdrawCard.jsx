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
import { getTokenLabel } from '../../utils/currencies'
import { toWei } from '../../utils/conversions'

const { withdraw } = LiquidPledgingMock.methods

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
    return (
      <Formik
        initialValues={{}}
        onSubmit={async (values, { setSubmitting, resetForm, setStatus }) => {
          const { amount } = values
          const args = [rowData.id, toWei(amount)]
          withdraw(...args)
            .send()
            .then(res => {
              console.log({res})
            })
            .catch(e => {
              console.log({e})
            })
            .finally(() => {
              this.close()
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
          <Collapse in={show}>
            <form autoComplete="off" onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', marginBottom: '0px' }}>
              <Card className={classes.card} elevation={0}>
                <CardContent>
                  <Typography variant="h5" component="h2">
                    {`Withdraw ${values.amount || ''}  ${values.amount ? getTokenLabel(rowData[6]) : ''} from Pledge ${rowData.id}`}
                  </Typography>
                  <TextField
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
                  />
                </CardContent>
                <CardActions>
                  <Button size="large" variant="outlined" onClick={this.close}>Cancel</Button>
                  <Button size="large" variant="outlined" color="primary" type="submit">Withdraw</Button>
                </CardActions>
              </Card>
            </form>
          </Collapse>
        )}
      </Formik>
    )
  }
}

Withdraw.propTypes = {
  classes: PropTypes.object.isRequired,
  rowData: PropTypes.object.isRequired
}

export default withStyles(styles)(Withdraw)
