using DataStructures
using Graphs

# include("./ActivatedGraphs.jl")
# using .ActivatedGraphs


function _prepare_graph(
    index_times_start::Integer,
    g::ActivatedGraph{T}
)::Nothing where {T}

    (:times ∉ keys(g.arrays)) && error("`times` array is required")

    if :is_available ∉ keys(g.arrays)
        g[:is_available] = trues(g.len_array)
    end

    !g[:is_available][index_times_start] && error("`index_times_start` is not available")

    weights = g.graph.weights
    eltype_weights = eltype(weights)
    keys_in_arrays = (:parents, :lifetime, :dists, :roots, :is_leaf) .∈ (keys(g.arrays),)

    if !any(keys_in_arrays)
        @info "creating parents and lifetime"
        g[:parents] = zeros(T, g.len_array)
        g[:roots] = deepcopy(g[:parents])
        g[:is_leaf] = trues(g.len_array)
        g[:lifetime] = zeros(g.len_array)
        g[:dists] = fill(typemax(eltype_weights), g.len_array)
    elseif any(keys_in_arrays) && !all(keys_in_arrays)
        error("invalid arrays: $(keys(g.arrays))")
    elseif g[:parents][index_times_start] == -1
        error("start is already discovered as root")
        return
    elseif g[:parents][index_times_start] ≠ 0
        error("start is already discovered as intermediate")
        return
    end

    # t_start = g[:times][index_times_start]  not used, 
    g[:parents][index_times_start] = -1  # root
    g[:roots][index_times_start] = index_times_start  # is unique
    g[:dists][index_times_start] = 0

    return

end


function _clear_graph(g::ActivatedGraph)
    keys_delete = (:parents, :roots, :is_available, :dists, :lifetime, :is_leaf)
    for key in keys_delete
        delete!(g.arrays, key)
    end
end


function visit_breaks!(
    index_times_start::Integer;  # index for the `times` and `is_available`
    g::ActivatedGraph{T},
    dt_max::AbstractFloat
) where {T}

    _prepare_graph(index_times_start, g)

    weights = g.graph.weights
    eltype_weights = eltype(weights)

    pq = PriorityQueue{Tuple{T,T}, eltype_weights}()
    # (i_vertex, i_time) => (dist)

    v = find_vertex_id(g, index_times_start)
    pq[v, index_times_start] = 0.

    summary_info = Dict{Symbol, Real}(
        :n_visited => 1,
        :index_times_start => index_times_start,
        :time_start => g[:times][index_times_start],
        :lifetime_max => 0,
        :dist_lifetime_max => 0
    )

    summary_info[:index_times_finish] = summary_info[:index_times_start]
    summary_info[:time_finish] = summary_info[:time_start]

    conduction_found = :conduction in keys(g.arrays)

    while !isempty(pq)

        v, i_t_v = dequeue!(pq)
        t_v = g[:times][i_t_v]
        d_v = g[:dists][i_t_v]
        @debug "dequeue: $v, $i_t_v ($t_v, $d_v)"

        v_neighbors = neighbors(g, v)
        @debug "v_neighbors: $v_neighbors"

        for u in v_neighbors

            w_v_u = weights[v, u]
            @debug "next neighbor: $u\n\tweight: $w_v_u"
            
            for i_t_u = g.starts[u]:g.stops[u]

                @debug "$u, $i_t_u, ($(g[:times][i_t_u]), $(g[:dists][i_t_u]))"

                !g[:is_available][i_t_u] && continue

                (g[:parents][i_t_u] == -1) && continue  # root found
                #  actually this condition is never met

                conduction_found && isnan(g[:conduction][i_t_u]) && continue # the last beat

                t_u = g[:times][i_t_u]
                dt = t_u - t_v

                @debug "dt = $t_u - $t_v = $dt"

                if 0 < dt < dt_max  # forward evolution
                # if abs(dt) < dt_max  # forward and backward

                    dist_v_u = d_v + w_v_u

                    g[:is_leaf][i_t_v] = false

                    if g[:parents][i_t_u] == 0  # not visited yet

                        @debug "first time explored"

                        g[:parents][i_t_u] = i_t_v
                        g[:roots][i_t_u] = index_times_start
                        g[:dists][i_t_u] = dist_v_u

                        lifetime = g[:lifetime][i_t_v] + dt
                        g[:lifetime][i_t_u] = lifetime
                        summary_info[:n_visited] += 1

                        if lifetime > summary_info[:lifetime_max]
                            summary_info[:lifetime_max] = lifetime
                            summary_info[:dist_lifetime_max] = dist_v_u
                            summary_info[:index_times_finish] = i_t_u
                            summary_info[:time_finish] = t_u
                        end

                        pq[(u, i_t_u)] = dist_v_u

                    # this is almost useless
                    # and has some bug

                    elseif (g[:roots][i_t_u] == g[:roots][i_t_v]) && (dist_v_u < g[:dists][i_t_u])

                        # @info "shorter one: lifetime = $(g[:lifetime][i_t_v])"

                        g[:parents][i_t_u] = i_t_v
                        g[:dists][i_t_u] = dist_v_u
                        pq[(u, i_t_u)] = dist_v_u

                    end

                end

            end

        end

    end

    return summary_info

end
