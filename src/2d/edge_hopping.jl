using StatsBase


function select_outer_edge(point, points_triangle)

    n_vertices, n_dims = size(points_triangle)

    (n_vertices, n_dims) ≠ (3, 2) && error("this is not triangle")

    for i in 1:n_vertices
        indices = 1 .+ collect((i: i + n_dims)) .% n_vertices
        points_edge = points_triangle[indices, :]

        o⃗ = points_edge[1, :]
        a⃗ = points_edge[2, :] - o⃗  # the edge
        b⃗ = points_edge[3, :] - o⃗
        c⃗ = point - o⃗

        # @show scatterplot(
        #     [0, a⃗[1], b⃗[1], c⃗[1]],
        #     [0, a⃗[2], b⃗[2], c⃗[2]],
        #     marker=['o', 'a', 'b', 'c'],
        #     xlim=(-1000, 1000),
        #     ylim=(-1000, 1000)
        # )
        z1 = b⃗[1] * a⃗[2] - b⃗[2] * a⃗[1]
        z2 = c⃗[1] * a⃗[2] - c⃗[2] * a⃗[1]

        sign(z1) ≠ sign(z2) && return indices[1: 2]

    end

end


function edge_hopping(i_triangle_start, point, points, triangles, A_triangles; save_trace=false)

    trace = save_trace ? [i_triangle_start] : nothing

    rows = rowvals(A_triangles)

    while true

        point_indices = triangles[i_triangle_start, :]
        points_triangle = points[point_indices, :]
        edge_indices = select_outer_edge(point, points_triangle)

        # center = mean(coords_tetra, dims=1)[1, :]
        # @show dist_left = norm(center .- point)

        if isnothing(edge_indices)
            return (i = i_triangle_start, trace = trace)
        end

        point_indices_edge = point_indices[edge_indices]
        # @show point_indices_facet

        js = rows[nzrange(A_triangles, i_triangle_start)]
        i_element_proposed = nothing
        for j in js
            is_shared_edge = all(point_indices_edge .∈ (triangles[j, :],))
            if is_shared_edge
                i_element_proposed = j
                break
            end
        end

        if isnothing(i_element_proposed)
            # @warn "nothing found"
            break
        end
        
        i_triangle_start = i_element_proposed

        if save_trace
            push!(trace, i_element_proposed)
        end

    end
    
    return (i = nothing, trace = trace)

end


function edge_hopping(i_triangle_start, point, mesh::ActivatedMesh; save_trace=false)

    points = mesh[:points]
    triangles = mesh.elements
    A_triangles = mesh.graph_elements.weights

    edge_hopping(
        i_triangle_start,
        point,
        points,
        triangles,
        A_triangles;
        save_trace
    )

end
