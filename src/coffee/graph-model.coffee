# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph-model.coffee
#

# Graph model
class GraphModel
    nodePositions: null
    edges: null

    constructor: ->
        @clear()

    clear: ->
        @nodePositions = []
        @edges = []

    # node is an integer
    newNode: (x, y) ->
        nodeId = @nodePositions.length
        @nodePositions[nodeId] = { x: x, y: y }
        return nodeId

    numNodes: () ->
        return @nodePositions.length

    # edge is an array of the form [node_1, node_2]
    addEdge: (edge) ->
        @edges.push(edge)

    delNode: (node) ->
        edgeMatchPred = (edge) ->
            return (edge[0] == node or edge[1] == node)
        @edges = _.reject(@edges, edgeMatchPred)

    delEdge: (edge) ->
        edgeEQPred = (otherEdge) ->
            return (edge[0] == otherEdge[0] and edge[1] == otherEdge[1])
        util.removeAt(@edges, util.find(@edges, edgeEQPred))

    compact: (remap) ->
        for edge in @edges
            edge[0] = remap[edge[0]]
            edge[1] = remap[edge[1]]

        remappedNodePositions = []
        for i in [0..remap.length]
            if remap[i]?
                remappedNodePositions[remap[i]] = @nodePositions[i]
                
        @nodePositions = remappedNodePositions
        
exports = this
exports.GraphModel = GraphModel
