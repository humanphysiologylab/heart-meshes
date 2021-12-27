using DataStructures
using Distances: Euclidean, colwise
using Graphs: DijkstraState, AbstractGraph
using SparseArrays


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


function color_connected_components(components, n_max)

    color = zeros(Int, n_max)
    components_sorted = sort(collect(components); by = length, rev = true)

    for (i, component) in enumerate(components_sorted)
        color[collect(component)] .= i
    end

    return color

end


function dijkstra_many_sourses(
    g::AbstractGraph,
    srcs::Vector{U},
    distmx::AbstractMatrix{T} = weights(g),
) where {T<:Real} where {U<:Integer}

    nvg = nv(g)

    dists = fill(typemax(T), nvg)
    parents = zeros(U, nvg)
    visited = zeros(Bool, nvg)
    nearest_src = zeros(U, nvg)

    H = PriorityQueue{U,T}()

    for src in srcs
        dists[src] = zero(T)
        visited[src] = true
        H[src] = zero(T)

        nearest_src[src] = src
    end

    while !isempty(H)

        u = dequeue!(H)
        d = dists[u]

        for v in outneighbors(g, u)

            alt = d + distmx[u, v]

            if !visited[v]

                visited[v] = true
                dists[v] = alt
                parents[v] = u
                nearest_src[v] = nearest_src[u]
                H[v] = alt

            elseif alt < dists[v]

                nearest_src[v] = nearest_src[u]
                dists[v] = alt
                parents[v] = u
                H[v] = alt

            end
        end
    end

    preds = Vector{Vector{U}}()
    pathcounts = Vector{T}()

    return DijkstraState{T,U}(nearest_src, dists, preds, pathcounts, nearest_src)
end


function dijkstra_many_sourses_v2(
    g::AbstractGraph,
    srcs::Vector{U},
    distmx::AbstractMatrix{T} = weights(g),
) where {T<:Real} where {U<:Integer}

    nvg = nv(g)

    dists = fill(typemax(T), nvg)
    parents = zeros(U, nvg)
    visited = zeros(Bool, nvg)
    nearest_src = zeros(U, nvg)
    adj_matrix_srcs = spzeros(Bool, nvg, nvg)

    H = PriorityQueue{U,T}()

    for src in srcs
        dists[src] = zero(T)
        visited[src] = true
        H[src] = zero(T)

        nearest_src[src] = src
    end

    while !isempty(H)

        u = dequeue!(H)
        d = dists[u]

        for v in outneighbors(g, u)

            alt = d + distmx[u, v]

            if visited[v]

                if alt < dists[v]
                    nearest_src[v] = nearest_src[u]
                    dists[v] = alt
                    parents[v] = u
                    H[v] = alt
                else
                    u_src, v_src = nearest_src[u], nearest_src[v]
                    adj_matrix_srcs[u_src, v_src] = true
                end

            else

                visited[v] = true
                dists[v] = alt
                parents[v] = u
                nearest_src[v] = nearest_src[u]
                H[v] = alt

            end
        end
    end

    preds = Vector{Vector{U}}()
    pathcounts = Vector{T}()

    return DijkstraState{T,U}(nearest_src, dists, preds, pathcounts, nearest_src),
    adj_matrix_srcs
end
