using DataStructures
using SparseArrays
using UnPack: @unpack

include("./ActivatedGraphs.jl")
using .ActivatedGraphs


function visit_breaks!(
    index_times_start::Integer;  # index for the `times` and `is_available`
    g::ActivatedGraph{T},
    dt_max::AbstractFloat,
)::Int where {T}

    any((:times, :conduction) .∉ (keys(g.arrays),)) &&
        error("times and conduction are required")
    (g[:conduction][index_times_start] == 1) &&
        error("trajectory must start on the break (conduction < 1)")

    q = Queue{Tuple{T,T}}()  # (i_vertex, i_time)

    v = find_vertex_id(g, index_times_start)
    enqueue!(q, (v, index_times_start))

    keys_in_arrays = (:parents, :lifetime) .∈ (keys(g.arrays),)

    if !any(keys_in_arrays)
        @info "creating parents and lifetime"
        g[:parents] = zeros(T, g.len_array)
        g[:lifetime] = zeros(g.len_array)
    elseif any(keys_in_arrays) && !all(keys_in_arrays)
        error("invalid arrays: $(keys(g.arrays))")
    elseif g[:parents][index_times_start] == -1
        @warn "start is already discovered as root"
        return 0
    elseif g[:parents][index_times_start] ≠ 0
        @warn "start is already discovered as intermediate"
        return 0
    end

    g[:parents][index_times_start] = -1  # root

    n_visited = 0

    while !isempty(q)

        v, i_t_v = dequeue!(q)
        t_v = g[:times][i_t_v]
        @debug "dequeue: $v, $i_t_v ($t_v)"

        v_neighbors = neighbors(g, v)
        @debug "v_neighbors: $v_neighbors"

        for u in v_neighbors

            for i_t_u = g.starts[u]:g.stops[u]

                (g[:parents][i_t_u] ≠ 0) && continue  # already visited

                c_u = g[:conduction][i_t_u]
                ((c_u == 1) || (isnan(c_u))) && continue  # not break or the last beat

                t_u = g[:times][i_t_u]
                dt = t_u - t_v
                if dt < dt_max  # forward evolution
                    g[:parents][i_t_u] = i_t_v
                    g[:lifetime][i_t_u] = g[:lifetime][i_t_v] + dt
                    enqueue!(q, (u, i_t_u))
                    @debug "enqueue: $u, $i_t_u ($t_u)"
                    n_visited += 1
                end

            end

        end

    end

    return n_visited

end
