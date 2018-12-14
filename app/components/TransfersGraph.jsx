import Cytoscape from 'cytoscape'
import dagre from 'cytoscape-dagre'
import React, { Fragment } from 'react'
import CytoscapeComponent from 'react-cytoscapejs'
import { uniq } from 'ramda'
import { toEther } from '../utils/conversions'

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

const createElements = transfers => {
  const nodes = []
  const edges = []
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
  return [
    ...uniq(nodes),
    ...edges
  ]
}

const TransfersGraph = ({ transfers }) => {
  return (
    <Fragment>
      <CytoscapeComponent
        elements={createElements(transfers)}
        style={ { width: '100%', height: '600px', fontSize: '14px' } }
        stylesheet={stylesheet}
        layout={layout}
      />
    </Fragment>
  )
}

export default TransfersGraph
