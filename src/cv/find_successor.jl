using Graphs
using LinearAlgebra: norm


function find_successor(
    index_times_start::Integer;
    g::ActivatedGraph{T},
    is_forward=true,
    ∇t_min=0,
    ∇t_max=Inf
) where {T}

    current = Dict(
        :v => find_vertex_id(g, index_times_start),
        :t => g[:times][index_times_start],
        :i_t => index_times_start,
        :∇t => 0.
    )

    ζ = is_forward ? 1 : -1

    # us = neighbors(g, current[:v])

    neighborhood_max_dist = 2.
    us = neighborhood(g.graph, current[:v], neighborhood_max_dist)
    us = filter(x -> x ≠ current[:v], us)

    next = Dict(
        :v => 0,
        :t => 0.,
        :i_t => 0,
        :∇t => 0.,
        :dt => 0.
    )

    for u in us

        candidate = Dict(
            :dt⁺ => Inf,
            :t => 0.,
            :i_t => 0,
        )
        
        for i_t_u = g.starts[u]:g.stops[u]

            t_u = g[:times][i_t_u]
            dt = t_u - current[:t]

            dt⁺ = ζ * dt

            if 0 ≤ dt⁺ < candidate[:dt⁺]
                candidate[:dt⁺] = dt⁺
                candidate[:t] = t_u
                candidate[:i_t] = i_t_u
            end
                
        end

        distᵤᵥ = norm(g[:points][u, :] - g[:points][current[:v], :])
        ∇tᵤ = candidate[:dt⁺] / distᵤᵥ

        if !(∇t_min <= ∇tᵤ <= ∇t_max)
            @info "∇tᵤ is outside the bounds\n$∇t_min < $∇tᵤ < $∇t_max"
            continue
        end
        
        if next[:∇t] < ∇tᵤ
            next[:v] = u
            next[:∇t] = ∇tᵤ
            next[:t] = candidate[:t]
            next[:i_t] = candidate[:i_t]
            next[:dt] = candidate[:dt⁺] * ζ
        end

    end

    # if next[:v] ≠ 0
    #     if is_forward
    #         @assert next[:t] - current[:t] > 0
    #     else
    #         @assert next[:t] - current[:t] < 0 
    #     end
    # end

    next

end
