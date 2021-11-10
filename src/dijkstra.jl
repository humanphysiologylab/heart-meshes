using Dijkstra


function calculate_dijkstra_path(I, J, weights, index_start)

    G = Graph()

    for (i, j, w) in zip(I, J, weights)
        add_edge!(G, i, j, w)
    end

    ShortestPath(G, index_start)

end


function filter_dijkstra_path(path, radius)

    path_dist_keys = collect(keys(path.dist))
    path_dist_values = collect(values(path.dist))

    mask_radius = path_dist_values .<= radius

    path_dist_keys[mask_radius], path_dist_values[mask_radius]
end
