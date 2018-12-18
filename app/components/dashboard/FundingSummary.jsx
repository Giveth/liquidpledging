import React from 'react'
import PropTypes from 'prop-types'
import { withStyles } from '@material-ui/core/styles'
import Card from '@material-ui/core/Card'
import CardContent from '@material-ui/core/CardContent'
import Typography from '@material-ui/core/Typography'
import { FundingContext } from '../../context'
import { getDepositsTotal } from '../../selectors/pledging'
import { getAuthorizations } from '../../selectors/vault'

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
      {({ allPledges, allLpEvents }) =>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" component="h2">
              {title}
            </Typography>
            {!!allLpEvents &&
             Object.entries(getDepositsTotal({ allLpEvents, allPledges })).map(deposit => {
               const [name, amount] = deposit
               return (
                 <Typography key={name} className={classes.pos} color="textSecondary">
                   Total Funded: {amount} {name}
                 </Typography>
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
