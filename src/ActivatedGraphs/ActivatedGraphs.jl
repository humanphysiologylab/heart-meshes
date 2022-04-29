using SimpleWeightedGraphs, SparseArrays
import Base: getindex, setindex!, reduce
import Graphs: neighbors, nv, vertices

include("../ActArrays/ActArrays.jl")


struct ActivatedGraph{T<:Integer}
    graph::SimpleWeightedGraph{T}
    a::ActArray{T}
    scalars::Dict{Symbol,VecOrMat}

    function ActivatedGraph(
        graph::SimpleWeightedGraph{T},
        a::ActArray{T},
        scalars::Union{Dict{Symbol,<:VecOrMat}, Nothing} = nothing
    ) where {T<:Integer}

        (nv(graph) ≠ length(a)) && error("graph and arrays are not consistent")

        if isnothing(scalars)
            scalars = Dict{Symbol, VecOrMat}()
        else
            lengths = size.(values(scalars), 1)
            any(x -> x ≠ nv(graph), lengths) && error("scalars lengths are not consistent")
        end

        new{T}(graph, a, scalars)

    end

end


function ActivatedGraph(
    adj_matrix::SparseMatrixCSC{F, T},
    a::ActArray{T},
    scalars=nothing
) where {T<:Integer} where {F<:Real}
    graph = SimpleWeightedGraph{T, F}(adj_matrix)
    ActivatedGraph(graph, a, vectors, scalars)
end


Base.length(g::ActivatedGraph) = Base.length(g.a)
Base.getindex(g::ActivatedGraph, key::Symbol) = Base.getindex(g.a, key)
Base.setindex!(g::ActivatedGraph, value::AbstractArray, key::Symbol) = Base.setindex!(g.a, value, key)
Base.reduce(g::ActivatedGraph, key::Symbol, op=sum) = Base.reduce(g.a, key, op)

slice_arrays(g::ActivatedGraph, i::Integer) = slice_arrays(g.a, i)
get_subarray(g::ActivatedGraph, i::Integer, key::Symbol) = get_subarray(g.a, i, key)
get_subarrays(g::ActivatedGraph, i::Integer) = get_subarrays(g.a, i)
get_major_index(g::ActivatedGraph, i::Integer) = get_major_index(g.a, i)
get_native_index(g::ActivatedGraph, major_index::Integer, minor_index::Integer) = get_native_index(g.a, major_index, minor_index)

nv(g::ActivatedGraph) = nv(g.graph)
vertices(g::ActivatedGraph) = vertices(g.graph)
neighbors(g::ActivatedGraph, v::Integer) = neighbors(g.graph, v)


# function induced_subgraph(g::ActivatedGraph{T}, vlist::AbstractVector{<:Integer})
#     allunique(vlist) || throw(ArgumentError("Vertices in subgraph list must be unique"))
#     vlist = convert.(T, vlist)
#     starts_subset, stops_subset, vectors_subset_values =
#         create_arrays_subsets(g.starts, vlist, values(g.vectors))
#     keys_vectors = keys(g.vectors)
    
#     vectors_subset = Dict(zip(keys_vectors, vectors_subset_values))

#     scalars_subset = Dict{Symbol, VecOrMat}()
#     for (k, v) in g.scalars
#         if typeof(v) <: Vector
#             scalars_subset[k] = v[vlist]
#         elseif typeof(v) <: Matrix
#             scalars_subset[k] = v[vlist, :]
#         end
#     end
#     ActivatedGraph(g.graph[vlist], starts_subset, vectors_subset, scalars_subset)
# end

# getindex(g::ActivatedGraph, iter::AbstractVector{<:Integer}) = induced_subgraph(g, iter)
