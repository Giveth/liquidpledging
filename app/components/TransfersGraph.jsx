import Cytoscape from 'cytoscape'
import dagre from 'cytoscape-dagre'
import React, { Fragment } from 'react'
import CytoscapeComponent from 'react-cytoscapejs'

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

const TransfersGraph = () => {
  const elements = [
    { data: { id: 'one', label: 'Node 1' } },
    { data: { id: 'two', label: 'Node 2' } },
    { data: { id: 'three', label: 'Node 3' } },
    { data: { source: 'one', target: 'two', label: 'Edge from Node1 to Node2' } },
    { data: { source: 'one', target: 'three', label: 'Edge from Node1 to Node3' } }
  ]

  return (
    <Fragment>
      <CytoscapeComponent
        elements={elements}
        style={ { width: '100%', height: '600px', fontSize: '14px' } }
        stylesheet={stylesheet}
        layout={layout}
      />
    </Fragment>
  )
}

export default TransfersGraph
