using LinearAlgebra: norm


function calculate_time_gradient(times_index, ag, points; dt_threshold=20.)

    v = find_vertex_id(ag, times_index)
    v_t = ag[:times][times_index]

    # neighborhood_max_dist = 1000.
    # us = neighborhood(ag.graph, v, neighborhood_max_dist)
    # us = filter(x -> x ≠ v, us)

    us = neighbors(ag, v)

    dhs = [ag.graph.weights[v, u] for u in us]

    X = points[us, :]
    y = points[v, :]
    dX = X .- y'
    # dX_norm = dhs  # norm.(eachrow(dX))
    dX_norm = norm.(eachrow(dX))  # use for neighbourhood

    U = hcat(map(dx -> dx ./ dX_norm, eachcol(dX))...)

    dts = fill(Inf, length(us))

    for (u_i, u) in enumerate(us)
        u_times = get_vertex_vector(ag, u, :times)
        for u_t in u_times
            dt = u_t - v_t
            if abs(dt) < abs(dts[u_i])
                dts[u_i] = dt
            end
        end
    end

    # @show dts
    
    b = dts ./ dX_norm
    mask_threshold = @. 1e-3 < b < 1e-1
    ∇t = U[mask_threshold, :] \ b[mask_threshold]

    ∇t_norm = norm(∇t)  # ms / um
    CV_norm = 1 / ∇t_norm / 10  # cm / s
    ∇t_unit = ∇t / ∇t_norm

    (;∇t_norm, CV_norm, ∇t_unit)

end
