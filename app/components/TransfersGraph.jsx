import Cytoscape from 'cytoscape'
import dagre from 'cytoscape-dagre'
import React, { Fragment, memo } from 'react'
import CytoscapeComponent from 'react-cytoscapejs'
import { uniq } from 'ramda'
import { toEther } from '../utils/conversions'
import { getTokenLabel } from '../utils/currencies'

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

const getAuthorizations = events => events.filter(event => event.event === 'AuthorizePayment')
const createElements = (transfers, vaultEvents) => {
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

const TransfersGraph = ({ transfers, vaultEvents }) => {
  return (
    <Fragment>
      <CytoscapeComponent
        elements={createElements(transfers, vaultEvents)}
        style={ { width: '100%', height: '600px', fontSize: '14px' } }
        stylesheet={stylesheet}
        layout={layout}
      />
    </Fragment>
  )
}

export default memo(TransfersGraph)
