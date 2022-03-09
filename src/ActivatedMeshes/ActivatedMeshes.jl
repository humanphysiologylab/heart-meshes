module ActivatedMeshes

using Graphs, SimpleWeightedGraphs, SparseArrays
import Base: getindex, setindex!, reduce
import Graphs: neighbors, nv, vertices

include("../misc/create_stops.jl")

export ActivatedMesh,
    get_vertex_vector,
    get_vertex_id,
    get_tetra_points,
    getindex


struct ActivatedMesh{T<:Integer}
    graph_vertices::SimpleWeightedGraph{T}
    graph_elements::SimpleWeightedGraph{T}  # for adjacency matrix

    elements::Matrix{T}  # point indices which form the element

    starts::Vector{T}
    stops::Vector{T}
    vertex_vectors::Dict{Symbol,Array}  # ex: time, conduction
    vertex_vectors_len::T  # ex: length(time)
    # vectors_type::DataType
    vertex_scalars::Dict{Symbol,Array}  # ex: points coordinates

    function ActivatedMesh(
        graph_vertices::SimpleWeightedGraph{T},
        graph_elements::SimpleWeightedGraph{T},
        elements::Matrix{T},
        starts::Vector{T},
        vectors::Dict{Symbol,<:Vector},
        scalars::Union{Dict{Symbol,<:Array}, Nothing} = nothing
    ) where {T<:Integer}

        n_vertices = nv(graph_vertices)
        (n_vertices ≠ length(starts)) && error("graph_vertices and starts are inconsistent:\n$n_vertices ≠ $(length(starts))")

        n_elements = nv(graph_elements)
        (n_elements ≠ size(elements, 1)) && error("graph_elements and elements are inconsistent\n$n_elements ≠ $(length(elements))")

        # n_vertices_from_elements = max(elements...)
        # (n_vertices_from_elements ≠ n_vertices) && error("elements and graph_vertices are inconsistent\n$n_vertices_from_elements ≠ $n_vertices")

        if isnothing(scalars)
            scalars = Dict{Symbol, Array}()
        else
            lengths = size.(values(scalars), 1)
            any(x -> x ≠ nv(graph_vertices), lengths) && error("scalars have different lengths")
        end

        lengths = length.(values(vectors))
        len_first_vector = first(lengths)
        any(x -> x ≠ len_first_vector, lengths) && error("vectors have different lengths")

        stops = create_stops(starts, len_first_vector)
        new{T}(graph_vertices, graph_elements, elements, starts, stops, vectors, len_first_vector, scalars)

    end

end

function ActivatedMesh(
    A_vertices::SparseMatrixCSC{F, T},
    A_elements::SparseMatrixCSC,
    elements,
    starts,
    vectors,
    scalars=nothing
) where {T<:Integer} where {F<:Real}

    n, m = A_vertices.n, A_vertices.m
    (n ≠ m) && error("A_vertices is not square")
    length_starts = length(starts)
    (n ≠ length_starts) && error("adj_matrix and starts are not consistent: $n ≠ $length_starts")
    
    n, m = A_elements.n, A_elements.m
    (n ≠ m) && error("A_elements is not square")

    graph_vertices = SimpleWeightedGraph{T, F}(A_vertices)
    graph_elements = SimpleWeightedGraph{T}(A_elements)

    ActivatedMesh(graph_vertices, graph_elements, elements, starts, vectors, scalars)
end


function get_vertex_vector(mesh::ActivatedMesh{T}, v::Integer, key::Symbol) where T
    v = T.(v)
    @view mesh.vertex_vectors[key][mesh.starts[v]: mesh.stops[v]]
end


function get_vertex_id(mesh::ActivatedMesh{T}, index_in_vector::Integer) where T
    i = T(index_in_vector)
    vertex_id = searchsortedlast(mesh.starts, i)
    T(vertex_id)
end


function getindex(mesh::ActivatedMesh, key::Symbol)
    if key in keys(mesh.vertex_vectors)
        return mesh.vertex_vectors[key]
    elseif key in keys(mesh.vertex_scalars)
        return mesh.vertex_scalars[key]
    else
        error("$key not found")
    end
end

function get_tetra_points(mesh::ActivatedMesh, i::Integer)
    mesh[:points][mesh.elements[i, :], :]
end

end  # module
