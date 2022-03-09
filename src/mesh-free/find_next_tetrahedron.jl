function find_next_tetrahedron(mesh, index_tetrahedron, p, time; direction=:backward, plane_indices_skip=nothing)

    t = mesh.elements[index_tetrahedron, :]
    t_coords = get_tetra_points(mesh, index_tetrahedron)
    @show t_times = find_nearest_times(mesh, t, time)
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
