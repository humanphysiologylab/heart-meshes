using DataStructures
using ProgressMeter

include("find_successor.jl")


function find_pools(
    g::ActivatedGraph{T};
    is_forward=true,
    neighborhood_max_dist=1000.,
    ∇t_min=1e-3,
    ∇t_max=1e-1
) where {T}

    indices = eltype(g.starts).(1: g.vectors_len)
    pools = DisjointSets(indices)

    g[:successor] = zeros(eltype(g.starts), g.vectors_len)

    @showprogress for i in indices

        !g[:is_available][i] && continue

        successor = find_successor(
            i; g, is_forward, neighborhood_max_dist, ∇t_min, ∇t_max
        )
        j = successor[:i_t]

        if j ≠ 0
            union!(pools, i, j)
            g[:successor][i] = j
        end

    end

    pools

end
