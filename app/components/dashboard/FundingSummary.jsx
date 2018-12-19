import React from 'react'
import PropTypes from 'prop-types'
import { withStyles } from '@material-ui/core/styles'
import Card from '@material-ui/core/Card'
import CardContent from '@material-ui/core/CardContent'
import Typography from '@material-ui/core/Typography'
import { FundingContext } from '../../context'
import { getDepositWithdrawTotals } from '../../selectors/pledging'

const styles = {
  card: {
    minWidth: 275,
  },
  bullet: {
    display: 'inline-block',
    margin: '0 2px',
    transform: 'scale(0.8)',
  },
  title: {
    fontSize: 14,
  },
  pos: {
    marginBottom: 12,
  },
}

function SimpleCard(props) {
  const { classes, title } = props

  return (
    <FundingContext.Consumer>
      {({ allPledges, allLpEvents, vaultEvents }) =>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" component="h2">
              {title}
            </Typography>
            {!!allLpEvents &&
             Object.entries(getDepositWithdrawTotals({ allLpEvents, allPledges, vaultEvents }))
                   .map(token => {
                     const [name, amounts] = token
                     const { deposits, withdraws } = amounts
                     return (
                       <div key={name}>
                         <Typography key={name + 'withdraw'} className={classes.pos} color="textSecondary">
                           Funded: {deposits} {name}
                         </Typography>
                         <Typography key={name + 'deposit'} className={classes.pos} color="textSecondary">
                           Withdrawn: {withdraws} {name}
                         </Typography>
                         <Typography key={name + 'total'} className={classes.pos} color="textSecondary">
                           Net: {Number(deposits) - Number(withdraws)} {name}
                         </Typography>
                       </div>
                     )
                   })}
          </CardContent>
        </Card>
      }
    </FundingContext.Consumer>
  )
}

SimpleCard.propTypes = {
  classes: PropTypes.object.isRequired,
  title: PropTypes.string
}

export default withStyles(styles)(SimpleCard)
