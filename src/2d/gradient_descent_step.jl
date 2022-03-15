function gradient_descent_step(time, p, i_element, mesh; step=-1, strategy=:random)

    t = mesh.elements[i_element, :]

    t_coords = get_tetra_points(mesh, i_element)
    t_times = find_nearest_times(mesh, t, time)

    cv = calculate_cv(t_coords, t_times)
    cv_normalized = cv / norm(cv)

    p_next = p + step * cv_normalized
    i_next = edge_hopping(i_element, p_next, mesh)[1]

    if isnothing(i_next)

        if strategy == :random
            # randomly pick neighbour
            i_next = rand(neighbors(mesh.graph_elements, i_element))
            t_coords = get_tetra_points(mesh, i_next)
            p_next = mean(t_coords, dims=1)[1, :]
        
        elseif strategy == :closest

            # find closest neighbour in cv direction
            center =  mean(t_coords, dims=1)[1, :]
            candidates = neighbors(mesh.graph_elements, i_element)
            max_dot_product = -Inf
            for i in candidates
                coords_candidate = get_tetra_points(mesh, i)
                center_candidate = mean(coords_candidate, dims=1)[1, :]
                dot_product = (center_candidate - center) ⋅ cv
                if dot_product > max_dot_product
                    i_next = i
                    p_next = center_candidate
                    max_dot_product = dot_product
                end
            end

        else

            error("no such strategy: $strategy")
        
        end

    end

    time_next = interpolate_baricentric(
        p_next,
        get_tetra_points(mesh, i_next),
        find_nearest_times(mesh, mesh.elements[i_next, :], time)
    )

    return time_next, p_next, i_next

end
