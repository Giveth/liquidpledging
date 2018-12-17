import Cytoscape from 'cytoscape'
import dagre from 'cytoscape-dagre'
import React, { Fragment } from 'react'
import CytoscapeComponent from 'react-cytoscapejs'
import { uniq, isNil } from 'ramda'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'
import { FundingContext } from '../context'
import { getAuthorizations } from '../selectors/vault'


Cytoscape.use(dagre)
const layout = { name: 'dagre' }

const stylesheet = [
  {
    selector: 'node',
    style: {
      width: 5,
      height: 5,
      fontSize: '5px',
      color: 'blue',
      label: 'data(label)'
    }
  },
  {
    selector: 'edge',
    style: {
      label: 'data(label)',
      curveStyle: 'bezier',
      targetArrowShape: 'triangle',
      arrowScale: 0.5,
      fontSize: '5px',
      width: 1
    }
  }
]

const createElements = (transfers, vaultEvents) => {
  if (isNil(transfers) || isNil(vaultEvents)) return []
  const nodes = []
  const edges = []
  const authorizations = getAuthorizations(vaultEvents)
  transfers.forEach(transfer => {
    const { returnValues: { amount, from, to } } = transfer
    nodes.push({
      data: { id: from === '0' ? 'Create Funding' : from, label: `Pledge Id ${from}` }
    })
    nodes.push({
      data: { id: to, label: `Pledge Id ${to}` }
    })
    edges.push({
      data: { source: from === '0' ? 'Create Funding' : from, target: to, label: toEther(amount) }
    })
  })
  authorizations.forEach(auth => {
    const { returnValues: { amount, dest, token, ref } } = auth
    const reference = Number(ref.slice(2)).toString()
    if (!isNaN(reference)) {
      nodes.push({
        data: { id: dest, label: dest }
      })
      edges.push({
        data: { source: reference, target: dest, label: `Withdraw ${toEther(amount)} ${getTokenLabel(token)}`}
      })
    }
  })
  return [
    ...uniq(nodes),
    ...edges
  ]
}

const TransfersGraph = () => {
  return (
    <FundingContext.Consumer>
      {({ transfers, vaultEvents }) =>
        <Fragment>
          <CytoscapeComponent
            elements={createElements(transfers, vaultEvents)}
            style={ { width: '800px', height: '100%', fontSize: '14px' } }
            stylesheet={stylesheet}
            layout={layout}
          />
        </Fragment>
      }
    </FundingContext.Consumer>
  )
}

export default TransfersGraph
