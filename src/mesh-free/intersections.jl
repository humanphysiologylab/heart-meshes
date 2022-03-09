using LinearAlgebra


function intersect_plane(points_plane, o_line, l_line)
    # https://en.wikipedia.org/wiki/Line%E2%80%93plane_intersection

    o_plane = points_plane[1, :]
    n_plane = cross(
        points_plane[2, :] - o_plane,
        points_plane[3, :] - o_plane
    )

    d = (o_plane - o_line) ⋅ n_plane / (l_line ⋅ n_plane)

    d, o_line + l_line * d

end


function intersect_plane(points_plane, points_line)
    o_line = points_line[1, :]
    l_line = points_line[2, :] - o_line
    intersect_plane(points_plane, o_line, l_line)
end


function intersect_tetrahedron(tetrahedron, o_line, l_line; direction=:forward, plane_indices_skip=nothing)

    n_vertices, n_dims = size(tetrahedron)
    (n_vertices, n_dims) ≠ (4, 3) && error("wrong tetrahedron")

    result_indices = nothing
    result_coords = nothing
    d_best = Inf

    if direction == :forward
        ξ = 1
    elseif direction == :backward
        ξ = -1
    else
        error("unknown direction: $direction")
    end

    for i in 1: n_vertices

        indices = 1 .+ collect((i: i + n_dims - 1)) .% n_vertices

        if !isnothing(plane_indices_skip) && all(indices .∈ (plane_indices_skip,))
            @info "plane skipped" 
            continue
        end

        plane = tetrahedron[indices, :]
        @show d, x = intersect_plane(plane, o_line, l_line)

        (d * ξ < 0) && continue  # another direction

        !isnothing(result_indices) && (d * ξ > d_best * ξ) && continue 

        @info "update"
        result_indices = indices
        result_coords = x
        d_best = d

    end

    return (indices = result_indices, p = result_coords, d = d_best)

end
