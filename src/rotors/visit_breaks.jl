using DataStructures
using SparseArrays
using UnPack: @unpack

include("structs.jl")


function visit_breaks(
    index_times_start::Integer;  # index for the `times` and `is_available`
    act_graph::ActivatedGraph,
    is_available::Vector{Bool},
    is_visited::Vector{Bool},
    dt_max::AbstractFloat,
)::Integer

    if !is_available[index_times_start]
        error()
    end

    is_available[index_times_start] = false
    is_visited[index_times_start] = true

    q = Queue{Tuple{Integer,AbstractFloat}}()  # (vertex, time)

    @unpack starts, stops, times, adj_matrix = act_graph

    v = searchsortedlast(starts, index_times_start)
    t_v = act_graph.times[index_times_start]
    @debug "vertex start is $v with time $t_v"

    enqueue!(q, (v, t_v))

    rows = rowvals(adj_matrix)

    n_visited = 0

    while !isempty(q)

        v, t_v = dequeue!(q)
        @debug "dequeue: $v, $t_v"

        neighbours = @view rows[nzrange(adj_matrix, v)]
        @debug "neighbours: $neighbours"

        for u in neighbours

            start_u, stop_u = starts[u], stops[u]
            for index_t_u = start_u:stop_u

                !is_available[index_t_u] && continue

                t_u = times[index_t_u]
                dt = abs(t_u - t_v)
                if dt < dt_max
                    is_available[index_t_u] = false
                    is_visited[index_t_u] = true
                    enqueue!(q, (u, t_u))
                    @debug "enqueue: $u, $t_u"
                    n_visited += 1
                end

            end

        end

    end

    return n_visited

end
