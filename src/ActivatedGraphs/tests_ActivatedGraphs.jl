using Test
using SparseArrays
using Graphs, SimpleWeightedGraphs
include("./ActivatedGraphs.jl")
using .ActivatedGraphs

include("visit_breaks.jl")

##

times_ = [
    [1, 5, 8.1, 11],
    [2, 6, 8.2, 11.1],
    [3, 7, 9.0, 11.3],
    [4, 8, 10., 100.],
    [   7.5,    11.5],
    [2.01, 6.01, 8.21, 11.11]
]

stops = cumsum(length.(times_))
starts = similar(stops)
starts[2:end] = stops[1:end-1] .+ 1
starts[1] = 1

times = collect(Iterators.flatten(times_))

g = SimpleWeightedGraph(6)
# circle
add_edge!(g, 1, 2)
add_edge!(g, 2, 3)
add_edge!(g, 3, 4)
add_edge!(g, 4, 1)

# bypass
add_edge!(g, 3, 5)
add_edge!(g, 4, 5)

# branch
add_edge!(g, 2, 6)


ag = ActivatedGraph(g, starts, Dict(:times => times))

##

_clear_graph(ag)
visit_breaks!(1, g=ag, dt_max=1.1)

@test ag[:parents] == [-1, 13, 14, 15, 1, 2, 3, 4, 5, 6, 14, 8, 9, 10, 11, 0, 10, 12, 5, 6, 7, 8]
