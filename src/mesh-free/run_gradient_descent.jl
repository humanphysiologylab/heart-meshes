function run_gradient_descent(
    mesh,
    i = nothing,;
    t_start = 7500.,
    cb_capacity = 100,
    cb_threshold = 1e-3,
    step = -100,
    strategy = :random
)

    index_tetrahedron = isnothing(i) ? rand(1:nv(mesh.graph_elements)) : i

    t = mesh.elements[index_tetrahedron, :]
    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_center = mean(t_coords, dims=1)[1, :]
    t_times = find_nearest_times(mesh, t, t_start)
    t_start = mean(t_times)

    cb = CircularBuffer{typeof(t_start)}(cb_capacity)

    rows = []

    t_next, p_next = t_start, t_center
    i_next = index_tetrahedron

    row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
    push!(rows, row)

    while true
        t_next, p_next, i_next = gradient_descent_step(t_next, p_next, i_next, mesh; step, strategy)
        push!(cb, t_next)
        # terminate(cb, cb_threshold) && break
        if terminate(cb, cb_threshold)
            @info "terminated at $t_next"
            break
        end
        row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
        push!(rows, row)

        t_next < 2550. && break

    end

    df = DataFrame(rows)

end
