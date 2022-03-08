module ActivatedGraphs

using SimpleWeightedGraphs, SparseArrays
import Base: getindex, setindex!, reduce
import Graphs: neighbors, nv, vertices

include("../misc/create_stops.jl")

export ActivatedGraph,
    nv, neighbors, get_vertex_vector, find_vertex_id, getindex, setindex!, induced_subgraph


struct ActivatedGraph{T<:Integer}
    graph::SimpleWeightedGraph{T}
    starts::Vector{T}
    stops::Vector{T}
    vectors::Dict{Symbol,Vector}
    vectors_len::T
    vectors_type::DataType
    scalars::Dict{Symbol,VecOrMat}

    function ActivatedGraph(
        graph::SimpleWeightedGraph{T},
        starts::Vector{T},
        vectors::Dict{Symbol,<:Vector},
        scalars::Union{Dict{Symbol,<:VecOrMat}, Nothing} = nothing
    ) where {T<:Integer}

        (nv(graph) ≠ length(starts)) && error("graph and starts are not consistent")

        if isnothing(scalars)
            scalars = Dict{Symbol, VecOrMat}()
        else
            lengths = size.(values(scalars), 1)
            any(x -> x ≠ nv(graph), lengths) && error("scalars lengths are not consistent")
        end

        lengths = length.(values(vectors))
        len_first_vector = first(lengths)
        any(x -> x ≠ len_first_vector, lengths) && error("vectors have different lengths")

        stops = create_stops(starts, len_first_vector)
        new{T}(graph, starts, stops, vectors, len_first_vector, T, scalars)

    end

end


function ActivatedGraph(
    adj_matrix::SparseMatrixCSC{F, T},
    starts,
    vectors,
    scalars=nothing
) where {T<:Integer} where {F<:Real}
    n, m = adj_matrix.n, adj_matrix.m
    (n ≠ m) && error("adj_matrix is not square")
    length_starts = length(starts)
    (n ≠ length_starts) && error("adj_matrix and starts are not consistent: $n ≠ $length_starts")
    graph = SimpleWeightedGraph{T, F}(adj_matrix)
    ActivatedGraph(graph, starts, vectors, scalars)
end


nv(g::ActivatedGraph) = nv(g.graph)

vertices(g::ActivatedGraph) = vertices(g.graph)

neighbors(g::ActivatedGraph, v::Integer) = neighbors(g.graph, v)


function get_vertex_vector(g::ActivatedGraph{T}, v::Integer, key::Symbol) where T
    v = T.(v)
    @view g.vectors[key][g.starts[v]:g.stops[v]]
end


function find_vertex_id(g::ActivatedGraph{T}, index_in_vector::Integer) where T
    i = T(index_in_vector)
    vertex_id = searchsortedlast(g.starts, i)
    T(vertex_id)
end


function induced_subgraph(g::ActivatedGraph, vlist::AbstractVector{<:Integer})
    allunique(vlist) || throw(ArgumentError("Vertices in subgraph list must be unique"))
    vlist = convert.(g.vectors_type, vlist)
    starts_subset, stops_subset, vectors_subset_values =
        create_arrays_subsets(g.starts, vlist, values(g.vectors))
    keys_vectors = keys(g.vectors)
    
    vectors_subset = Dict(zip(keys_vectors, vectors_subset_values))

    scalars_subset = Dict{Symbol, VecOrMat}()
    for (k, v) in g.scalars
        if typeof(v) <: Vector
            scalars_subset[k] = v[vlist]
        elseif typeof(v) <: Matrix
            scalars_subset[k] = v[vlist, :]
        end
    end
    ActivatedGraph(g.graph[vlist], starts_subset, vectors_subset, scalars_subset)
end


function getindex(g::ActivatedGraph, key::Symbol)
    if key in keys(g.vectors)
        return g.vectors[key]
    elseif key in keys(g.scalars)
        return g.scalars[key]
    else
        error("$key not found")
    end
end
    

getindex(g::ActivatedGraph, iter::AbstractVector{<:Integer}) = induced_subgraph(g, iter)


function setindex!(g::ActivatedGraph, value::AbstractVector, key::Symbol)
    (length(value) != g.vectors_len) && error("invalid vector size")
    g.vectors[key] = value
end


function slice_arrays(g, index_in_vectors)
    Dict(k => v[index_in_vectors] for (k, v) in g.vectors)
end

function reduce(g::ActivatedGraph, key::Symbol, op=sum)

    result = map(vertices(g.graph)) do i
        get_vertex_vector(g, i, key) |> op
    end

end

end  # module
