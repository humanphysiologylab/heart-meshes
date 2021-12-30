module ActivatedGraphs

using Graphs, SparseArrays
import Base: getindex, setindex!
import Graphs: neighbors, nv

include("../misc/create_stops.jl")

export ActivatedGraph,
    nv, neighbors, get_vertex_array, find_vertex_id, getindex, setindex!, induced_subgraph


struct ActivatedGraph{T<:Integer}
    graph::SimpleGraph{T}
    starts::Vector{T}
    stops::Vector{T}
    arrays::Dict{Symbol,Vector}
    len_array::T
    type_array::DataType

    function ActivatedGraph(
        graph::SimpleGraph{T},
        starts::Vector{T},
        arrays::Dict{Symbol,<:Vector},
    ) where {T<:Integer}

        (nv(graph) ≠ length(starts)) && error("graph and starts are not consistent")

        lengths = length.(values(arrays))
        len_first_array = first(lengths)
        any(x -> x ≠ len_first_array, lengths) && error("arrays have different lengths")

        stops = create_stops(starts, len_first_array)
        new{T}(graph, starts, stops, arrays, len_first_array, T)

    end

end


function ActivatedGraph(
    adj_matrix::SparseMatrixCSC,
    starts::Vector{T},
    arrays::Dict{Symbol,<:Vector},
) where {T<:Integer}
    ActivatedGraph(SimpleGraph{T}(adj_matrix), starts, arrays)
end


nv(g::ActivatedGraph) = nv(g.graph)

neighbors(g::ActivatedGraph, v::Integer) = Graphs.neighbors(g.graph, v)


function get_vertex_array(g::ActivatedGraph, v::Int, key::Symbol)
    @view g.arrays[key][g.starts[v]:g.stops[v]]
end


function add_arrays!(g::ActivatedGraph; arrays...)
    for (key, value) in arrays
        (length(value) != g.len_array) && error("invalid array size")
        g.arrays[key] = value
    end
end


function find_vertex_id(g::ActivatedGraph{T}, index_array::Integer) where {T}
    i = T(index_array)
    vertex_id = searchsortedlast(g.starts, i)
    T(vertex_id)
end


function induced_subgraph(g::ActivatedGraph, vlist::AbstractVector{<:Integer})
    allunique(vlist) || throw(ArgumentError("Vertices in subgraph list must be unique"))
    vlist = convert.(g.type_array, vlist)
    starts_subset, stops_subset, arrays_subset =
        create_arrays_subsets(g.starts, vlist, values(g.arrays))
    keys_arrays = keys(g.arrays)
    ActivatedGraph(g.graph[vlist], starts_subset, Dict(zip(keys_arrays, arrays_subset)))
end


getindex(g::ActivatedGraph, key::Symbol) = g.arrays[key]

getindex(g::ActivatedGraph, iter::AbstractVector{<:Integer}) = induced_subgraph(g, iter)


function setindex!(g::ActivatedGraph, value::Vector{T}, key::Symbol) where {T}
    (length(value) != g.len_array) && error("invalid array size")
    g.arrays[key] = value
end


end  # module
