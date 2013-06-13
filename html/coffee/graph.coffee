# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# graph.coffee
#


class Graph
    nodes: null
    edges: null
    
    constructor: ->
        @clear()
    
    clear: ->
        @nodes = []
        @edges = []
        
    addNode: (node) ->
        @nodes.push(node)
        
    addEdge: (edge) ->
        @edges.push(edge)
        
    delNode: (node) ->
        util.remove(@nodes, node)
        
    delEdge: (edge) ->
#        util.remove(@edges, edge)
        
    matrix: ->
        len = @nodes.length
        m = for i in [0...len]
                for j in [0...len]
                    0
                    
        for edge in @edges
            m[edge[0]][edge[1]] = 1
    
        return m
    
    matrixAsText: ->
        m = @matrix()
        text = ""
        for i in [0...m.length]
            if i > 0 then text += "\n"
            for j in [0...m[i].length]
                text += m[i][j].toString() + " "
        text += "\n"
        
        return text

exports = this
exports.Graph = Graph
