# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph-model.coffee
#

# Graph model
class GraphModel
    nodes: null
    edges: null
    
    constructor: ->
        @clear()

    clear: ->
        @nodes = []
        @edges = []

    # node is an integer
    newNode: (x, y) ->
        nodeId = @nodes.length
        @nodes[nodeId] = { x: x, y: y }
        return nodeId

    numNodes: () ->
        return @nodes.length

    # edge is an array of the form [node_1, node_2]
    addEdge: (edge) ->
        @edges.push(edge)

    delNode: (node) ->
        edgeMatchPred = (edge) ->
            return (edge[0] == node or edge[1] == node)
        @edges = _.reject(@edges, edgeMatchPred)
        @nodes[node].del = true

    delEdge: (edge) ->
        edgeEQPred = (otherEdge) ->
            return (edge[0] == otherEdge[0] and edge[1] == otherEdge[1])
        util.removeAt(@edges, util.find(@edges, edgeEQPred))

    compact: () ->
        console.log("compacting")
        remap = []
        delta = 0
        for i in [0...@nodes.length]
            if @nodes[i].del
                delta++
            else
                remap[i] = i - delta

        console.log(remap)
        
        for edge in @edges
            edge[0] = remap[edge[0]]
            edge[1] = remap[edge[1]]

        remappedNodes = []
        for i in [0..remap.length]
            if remap[i]?
                remappedNodes[remap[i]] = @nodes[i]
                
        @nodes = remappedNodes
        
        return remap
        
exports = this
exports.GraphModel = GraphModel
