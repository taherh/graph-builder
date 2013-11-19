# Copyright (c) 2013 Taher Haveliwala
# All Rights Reserved
#
# See LICENSE for licensing
#
# matrix-view.coffee
#

# matrix view of graph
class MatrixView
    # return matrix corresponding to  graph
    asMatrix: (graph) ->
        len = graph.numNodes()
        # create nXn matrix initialized to [0]
        m = for i in [0...len]
                for j in [0...len]
                    0
                    
        # loop through edgelist and fill in matrix accordingly
        for edge in graph.edges
            m[edge[0]][edge[1]] = 1
    
        return m
    
    # return text representation of matrix corresponding to current graph
    asText: (graph) ->
        m = @asMatrix(graph)
        text = ""
        for i in [0...m.length]
            if i > 0 then text += "\n"
            for j in [0...m[i].length]
                if j > 0 then text += " "
                text += m[i][j].toString()
        text += "\n"
        
        return text

exports = this
exports.MatrixView = MatrixView
