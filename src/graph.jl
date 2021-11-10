using SparseArrays
using Distances: Euclidean, colwise
using NearestNeighbors: inrange


include("dijkstra.jl")


function create_adjacency_matrix(elements::Matrix{T}) where {T}

    # if min(elements...) ≠ 0
    #     @warn "minumum of the elements is not zero"
    # end

    element_size = size(elements)[2]

    Is = T[]
    Js = T[]

    @info "I and J calculation..."

    for i = 1:element_size-1
        for j = i+1:element_size
            I = elements[:, i] .+ 1
            J = elements[:, j] .+ 1
            append!(Is, I...)
            append!(Js, J...)
        end
    end

    @info "SparseMatrix filling..."

    S = sparse(Is, Js, ones(Bool, length(Is)))
    S .|= transpose(S)
    return S
end


function breadth_first_search(
    adjacency_matrix::SparseMatrixCSC{Bool,T},
    start = 1,
) where {T}

    n_vertices = size(adjacency_matrix)[1]
    visited = zeros(Bool, n_vertices)
    queue = Set{T}(start)

    while !isempty(queue)

        vertex = pop!(queue)
        visited[vertex] = true

        neigbours = findnz(adjacency_matrix[vertex, :])[1]
        for u in neigbours
            if !visited[u]
                visited[u] = true
                push!(queue, u)
            end
        end
    end

    return visited

end


function find_connected_components(adjacency_matrix, start = 1)

    components = Set{Int}[]
    n_vertices = size(adjacency_matrix)[1]
    visited_total = zeros(Bool, n_vertices)

    while !isnothing(start)

        visited = breadth_first_search(adjacency_matrix, start)
        component = Set(findall(visited))
        push!(components, component)

        visited_total .|= visited

        # @show start, length(component)   
        start = findfirst(!, visited_total)

    end

    return components

end


function color_connected_components(components, n_max)

    color = zeros(Int, n_max)
    components_sorted = sort(collect(components); by = length, rev = true)

    for (i, component) in enumerate(components_sorted)
        color[collect(component)] .= i
    end

    return color

end


function find_indices_ball(index_center, radius, points, adjacency_matrix, btree)
    pₒ = points[:, index_center]
    indices_ball = inrange(btree, pₒ, radius, false)
end


function find_area(index_center, radius, points, adjacency_matrix, btree)

    indices_ball = find_indices_ball(index_center, radius, points, adjacency_matrix, btree)

    points_ball = points[:, indices_ball]
    adj_ball = adjacency_matrix[indices_ball, indices_ball]

    I_ball, J_ball, V_ball = findnz(adj_ball)
    index_center_ball = findfirst(isequal(index_center), indices_ball)

    weights = colwise(Euclidean(), points_ball[:, I_ball], points_ball[:, J_ball])

    path = calculate_dijkstra_path(I_ball, J_ball, weights, index_center_ball)

    path_filtered_indices, path_filtered_weights = filter_dijkstra_path(path, radius)

    return indices_ball[path_filtered_indices], path_filtered_weights

end
