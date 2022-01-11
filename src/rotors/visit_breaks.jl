using DataStructures
using Graphs

# include("./ActivatedGraphs.jl")
# using .ActivatedGraphs


function visit_breaks!(
    index_times_start::Integer;  # index for the `times` and `is_available`
    g::ActivatedGraph{T},
    dt_max::AbstractFloat
) where {T}

    any((:times, :conduction) .∉ (keys(g.arrays),)) &&
        error("times and conduction are required")
    (g[:conduction][index_times_start] == 1) &&
        error("trajectory must start on the break (conduction < 1)")

    weights = g.graph.weights
    eltype_weights = eltype(weights)
    keys_in_arrays = (:parents, :lifetime, :dists, :roots) .∈ (keys(g.arrays),)

    if !any(keys_in_arrays)
        @info "creating parents and lifetime"
        g[:parents] = zeros(T, g.len_array)
        g[:roots] = deepcopy(g[:parents])
        g[:lifetime] = zeros(g.len_array)
        g[:dists] = fill(typemax(eltype_weights), g.len_array)
    elseif any(keys_in_arrays) && !all(keys_in_arrays)
        error("invalid arrays: $(keys(g.arrays))")
    elseif g[:parents][index_times_start] == -1
        @warn "start is already discovered as root"
        return 0
    elseif g[:parents][index_times_start] ≠ 0
        @warn "start is already discovered as intermediate"
        return 0
    end

    pq = PriorityQueue{Tuple{T,T}, eltype_weights}(Base.Order.Reverse)
    # (i_vertex, i_time) => (lifetime)

    v = find_vertex_id(g, index_times_start)
    pq[v, index_times_start] = 0.

    # t_start = g[:times][index_times_start]  not used, 
    g[:parents][index_times_start] = -1  # root
    g[:roots][index_times_start] = index_times_start  # is unique
    g[:dists][index_times_start] = 0

    summary_info = Dict{Symbol, Real}(
        :n_visited => 0,
        :lifetime_max => 0,
        :dist_lifetime_max => 0
    )

    while !isempty(pq)

        v, i_t_v = dequeue!(pq)
        t_v = g[:times][i_t_v]
        d_v = g[:dists][i_t_v]
        @debug "dequeue: $v, $i_t_v ($t_v, $d_v)"

        v_neighbors = neighbors(g, v)
        @debug "v_neighbors: $v_neighbors"

        for u in v_neighbors

            w_v_u = weights[v, u]

            for i_t_u = g.starts[u]:g.stops[u]

                # @debug "$u, $i_t_u, ($(g[:times][i_t_u]), $(g[:dists][i_t_u]))"

                (g[:parents][i_t_u] == -1) && continue  # root found
                #  actually this condition is never met

                c_u = g[:conduction][i_t_u]
                ((c_u == 1) || (isnan(c_u))) && continue  # not break or the last beat

                t_u = g[:times][i_t_u]
                dt = t_u - t_v

                # if 0 < dt < dt_max  # forward evolution
                if abs(dt) < dt_max  # forward and backward

                    dist_v_u = d_v + w_v_u

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
                        end

                        pq[(u, i_t_u)] = lifetime

                    # this is almost useless
                    # elseif dist_v_u < g[:dists][i_t_u]

                    #     @info "shorter one"

                    #     g[:parents][i_t_u] = i_t_v
                    #     g[:dists][i_t_u] = dist_v_u
                    #     enqueue!(q, (u, i_t_u))

                    end

                end

            end

        end

    end

    return summary_info

end
