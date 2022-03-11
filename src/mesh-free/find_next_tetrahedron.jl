function find_next_tetrahedron(mesh, index_tetrahedron, p, time; direction=:backward, plane_indices_skip=nothing)

    t = mesh.elements[index_tetrahedron, :]
    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_times = find_nearest_times(mesh, t, time)
    t_neighbors = neighbors(mesh.graph_elements, index_tetrahedron)
    cv = calculate_cv(t_coords, t_times)

    plane_indices_skip_local = nothing
    if !isnothing(plane_indices_skip)
        plane_indices_skip_local = findall(t .∈ (plane_indices_skip, ))
    end
    
    indices, p_next, d = intersect_tetrahedron(t_coords, p, cv; direction, plane_indices_skip=plane_indices_skip_local)

    # margin = 0.1
    # d *= (1 + margin)
    # p_next = p + d .* cv 

    isnothing(indices) && return

    plane_indices = t[indices]

    for next in t_neighbors
        vertices = mesh.elements[next, :]
        if all( plane_indices .∈ (vertices,) )
            t_next = interpolate_baricentric(p_next, t_coords, t_times)
            return (;next, p_next, t_next, plane_indices, cv)
        end
    end
    
end


function find_next_tetrahedron_v2(mesh, index_tetrahedron, p, time; direction=:backward)

    t = mesh.elements[index_tetrahedron, :]
    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_times = find_nearest_times(mesh, t, time)
    t_neighbors = neighbors(mesh.graph_elements, index_tetrahedron)
    cv = calculate_cv(t_coords, t_times)

    planes_indices_local, points, ds = intersect_tetrahedron_full(t_coords, p, cv)

    ξ = (forward = 1, backward = -1)[direction]

    i_found = nothing
    d_best = nothing

    for i in 1: size(points, 1)

        point = points[i, :]
        @show λ⃗ = calculate_baricentric_coordinates(point, t_coords)

        !is_inside(λ⃗) && continue
        @show "inside"

        d = ds[i]

        (sign(ξ) != sign(d)) && (abs(d) > 1e-4) && continue

        if isnothing(d_best) || (d_best * ξ < d * ξ)
            d_best = d
            i_found = i
            @show "new best" i, d
        end

    end

    # margin = 0.1
    # d *= (1 + margin)
    # p_next = p + d .* cv 

    isnothing(i_found) && return

    p_next = points[i_found, :]
    plane_indices_local = planes_indices_local[i_found, :]
    plane_indices = t[plane_indices_local]

    for next in t_neighbors
        vertices = mesh.elements[next, :]
        if all( plane_indices .∈ (vertices,) )
            t_next = interpolate_baricentric(p_next, t_coords, t_times)
            return (;next, p_next, t_next, plane_indices, cv)
        end
    end
    
end
