import React from 'react'
import PropTypes from 'prop-types'
import { withStyles } from '@material-ui/core/styles'
import Card from '@material-ui/core/Card'
import CardActions from '@material-ui/core/CardActions'
import CardContent from '@material-ui/core/CardContent'
import Button from '@material-ui/core/Button'
import Typography from '@material-ui/core/Typography'
import randomMC from 'random-material-color'
import { Doughnut } from 'react-chartjs-2'
import { FundingContext } from '../../context'
import { toEther } from '../../utils/conversions'
import { getTokenLabel } from '../../utils/currencies'

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

const pledgesChartData = pledges => {
  const data = []
  const labels = []
  const backgroundColor = []
  pledges.forEach(pledge => {
    const { id, amount, token } = pledge
    const converted = toEther(amount)
    data.push(converted)
    labels.push(
      `pledge ${id} - ${getTokenLabel(token)}`
    )
    backgroundColor.push(randomMC.getColor({ text: `${id}` }))
  })
  return {
    datasets: [
      {
        data,
        backgroundColor,
        hoverBackgroundColor: backgroundColor
      }
    ],
    labels
  }
}

function SimpleCard(props) {
  const { classes, title } = props

  return (
    <FundingContext.Consumer>
      {({ allPledges }) =>
        <Card className={classes.card}>
          <CardContent>
            <Typography variant="h5" component="h2">
              {title}
            </Typography>
            <Typography className={classes.pos} color="textSecondary">
              How your funds are distributed among pledges
            </Typography>
            <Doughnut data={pledgesChartData(allPledges)} />
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
