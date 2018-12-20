import React from 'react'
import PropTypes from 'prop-types'
import { withStyles } from '@material-ui/core/styles'
import Card from '@material-ui/core/Card'
import CardContent from '@material-ui/core/CardContent'
import Typography from '@material-ui/core/Typography'
import LinearProgress from '@material-ui/core/LinearProgress'
import { FundingContext } from '../../context'
import { getDepositWithdrawTotals } from '../../selectors/pledging'

const styles = {
  card: {
    minWidth: 275,
  },
  cardTitle: {
    paddingBottom: '1rem'
  },
  fundingSummaries: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center'
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
  linearColorPrimary: {
    backgroundColor: '#b2dfdb',
  },
  linearBarColorPrimary: {
    backgroundColor: '#00695c',
  },
  titleText: {
    textAlign: 'center',
    paddingTop: '2rem'
  }
}

const getNet = (deposits, withdraws) => Number(deposits) - Number(withdraws)
const getValue = (deposits, withdraws) => (getNet(deposits, withdraws) / Number(deposits)) * 100
function SimpleCard(props) {
  const { classes, title } = props

  return (
    <FundingContext.Consumer>
      {({ allPledges, allLpEvents, vaultEvents }) =>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" className={classes.cardTitle}>
              {title}
            </Typography>
            {!!allLpEvents &&
             Object.entries(getDepositWithdrawTotals({ allLpEvents, allPledges, vaultEvents }))
                   .map(token => {
                     const [name, amounts] = token
                     const { deposits, withdraws } = amounts
                     return (
                       <Card key={name}>
                         <Typography variant="h5" className={classes.titleText}>
                           {name}
                         </Typography>
                         <CardContent className={classes.fundingSummaries}>
                           <Typography variant="h2">
                             {Number(deposits) - Number(withdraws)}
                           </Typography>
                           <Typography variant="h5" key={name + 'total'} className={classes.pos} color="textSecondary">
                             Remaining In Pledges
                           </Typography>
                           <Typography variant="h3" >
                             {deposits}
                           </Typography>
                           <Typography variant="h6" key={name + 'withdraw'} className={classes.pos} color="textSecondary">
                             Funded
                           </Typography>
                           <Typography variant="h3">
                             {withdraws}
                           </Typography>
                           <Typography variant="h6" key={name + 'deposit'} className={classes.pos} color="textSecondary">
                             Withdrawn
                           </Typography>
                         </CardContent>
                         <LinearProgress
                           classes={{
                             colorPrimary: classes.linearColorPrimary,
                             barColorPrimary: classes.linearBarColorPrimary,
                           }}
                           color="primary"
                           variant="buffer"
                           value={getValue(deposits, withdraws)}
                           valueBuffer={100}
                         />
                       </Card>
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
