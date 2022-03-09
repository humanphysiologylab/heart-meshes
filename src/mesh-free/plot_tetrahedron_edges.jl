function plot_tetrahedron_edges(t_coords)
    indices = [1, 2, 3, 4, 1, 3, 4, 2]
    t_center = mean(t_coords, dims=1)[1, :]
    t_coords_shrinked = @. t_center' + (t_coords - t_center') * 0.97
    t_coords_shrinked[indices, :]
end
