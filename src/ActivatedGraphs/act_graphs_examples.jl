using SparseArrays

include("./ActivatedGraphs.jl")
using .ActivatedGraphs


adj_matrix = spzeros(3, 3)

adj_matrix[1, 2] = 1
adj_matrix[2, 1] = 1

starts = [1, 3, 6]
times = collect(1:10.0)
conductions = rand(10)

ag = ActivatedGraph(adj_matrix, starts, Dict(:times => times, :conductions => conductions))

##

neighbors(ag, 1)

foo = rand(10)

ag[:foo] = foo

induced_subgraph(ag, [3, 1])
