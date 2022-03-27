using Graphs, SimpleWeightedGraphs, SparseArrays

include("../ActArrays/ActArrays.jl")
include("../misc/create_stops.jl")


struct ActivatedMesh{T<:Integer}
    graph_vertices::SimpleWeightedGraph{T}
    graph_elements::SimpleWeightedGraph{T}  # for adjacency matrix
    elements::Matrix{T}  # point indices which form the element
    arrays::ActArray{T}
    scalars::Dict{Symbol,Array}  # ex: points

    function ActivatedMesh(
        graph_vertices::SimpleWeightedGraph{T},
        graph_elements::SimpleWeightedGraph{T},
        elements::Matrix{T},
        arrays::ActArray{T},
        scalars::Union{Dict{Symbol,<:Array}, Nothing} = nothing
    ) where {T<:Integer}

        n_vertices = nv(graph_vertices)
        length_arrays = length(arrays)
        (n_vertices ≠ length_arrays) && error("graph_vertices and starts are inconsistent:\n$n_vertices ≠ $(length_arrays)")

        n_elements = nv(graph_elements)
        n = size(elements, 1)
        (n_elements ≠ n) && error("graph_elements and elements are inconsistent:\n$n_elements ≠ $n")

        # n_vertices_from_elements = max(elements...)
        # (n_vertices_from_elements ≠ n_vertices) && error("elements and graph_vertices are inconsistent\n$n_vertices_from_elements ≠ $n_vertices")

        if isnothing(scalars)
            scalars = Dict{Symbol, Array}()
        else
            lengths = size.(values(scalars), 1)
            any(x -> x ≠ n_vertices, lengths) && error("scalars have different lengths")
        end

        new{T}(graph_vertices, graph_elements, elements, arrays, scalars)

    end

end

function ActivatedMesh(
    A_vertices::SparseMatrixCSC{F, T},
    A_elements::SparseMatrixCSC,
    elements::Matrix{T},
    arrays::ActArray,
    scalars=nothing
) where {T<:Integer} where {F<:Real}

    n, m = A_vertices.n, A_vertices.m
    (n ≠ m) && error("A_vertices is not square")

    length_arrays = length(arrays)
    (n ≠ length_arrays) && error("A_vertices and arrays are not consistent: $n ≠ $length_arrays")
    
    n, m = A_elements.n, A_elements.m
    (n ≠ m) && error("A_elements is not square")

    graph_vertices = SimpleWeightedGraph{T, F}(A_vertices)
    graph_elements = SimpleWeightedGraph{T}(A_elements)

    ActivatedMesh(graph_vertices, graph_elements, elements, arrays, scalars)
end


function Base.getindex(mesh::ActivatedMesh, key::Symbol)
    if key in keys(mesh.scalars)
        return mesh.scalars[key]
    else
        return mesh.arrays[key]
    end
end


function get_element_points(mesh::ActivatedMesh, i::Integer)
    mesh[:points][mesh.elements[i, :], :]
end


function get_subarray(mesh::ActivatedMesh, i::Integer, key::Symbol)
    get_subarray(mesh.arrays, i, key)
end
