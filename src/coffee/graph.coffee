# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph.coffee
#

# Abstract representation of graph
class Graph
    numNodes: null
    edges: null

    constructor: ->
        @clear()

    clear: ->
        @numNodes = 0
        @edges = []

    # node is an integer
    addNode: (node) ->
        @numNodes++

    # edge is an array of the form [node_1, node_2]
    addEdge: (edge) ->
        @edges.push(edge)

    delNode: (node) ->
        edgeMatchPred = (edge) ->
            return (edge[0] == node or edge[1] == node)
        @edges = _.reject(@edges, edgeMatchPred)

    delEdge: (edge) ->
        console.log("delEdge", edge)
        edgeEQPred = (otherEdge) ->
            return (edge[0] == otherEdge[0] and edge[1] == otherEdge[1])
        util.removeAt(@edges, util.find(@edges, edgeEQPred))

    compact: (remap) ->
        for edge in @edges
            edge[0] = remap[edge[0]]
            edge[1] = remap[edge[1]]
        
        @numNodes = _.reduce(remap,
                            (memo, id) -> memo + (id? ? 0 : 1),
                            0)
        console.log("numNodes:", @numNodes)

    # return matrix corresponding to current graph
    matrix: ->
        len = @numNodes
        # create nXn matrix initialized to [0]
        m = for i in [0...len]
                for j in [0...len]
                    0
                    
        # loop through edgelist and fill in matrix accordingly
        for edge in @edges
            m[edge[0]][edge[1]] = 1
    
        return m
    
    # return text representation of matrix corresponding to current graph
    matrixAsText: ->
        m = @matrix()
        text = ""
        for i in [0...m.length]
            if i > 0 then text += "\n"
            for j in [0...m[i].length]
                if j > 0 then text += " "
                text += m[i][j].toString()
        text += "\n"
        
        return text

exports = this
exports.Graph = Graph
