# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph.coffee
#

# Representation of graph
class Graph
    nodes: null
    edges: null
    
    constructor: ->
        @clear()
    
    clear: ->
        @nodes = []
        @edges = []
        
    # node is an integer
    addNode: (node) ->
        @nodes.push(node)
    
    # edge is an array of the form [node_1, node_2]
    addEdge: (edge) ->
        @edges.push(edge)
        
    delNode: (node) ->
        util.remove(@nodes, node)
        # todo: renumber nodes in edge list
        
    delEdge: (edge) ->
#        util.remove(@edges, edge)
        
    # return matrix corresponding to current graph
    matrix: ->
        len = @nodes.length
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
