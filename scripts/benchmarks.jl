using BenchmarkTools

leafsize = 30
radius = 1e4

@benchmark BallTree(points; leafsize = leafsize, reorder = false)
btree = BallTree(points; leafsize = leafsize, reorder = false)

@benchmark find_ball(index_center, radius, points, S, btree)

@benchmark calculate_conduction_map($adj_matrix, $times_sorted, $starts, 10000)

@benchmark calculate_conduction_map(
    $adj_matrix,
    $times_sorted,
    $starts,
    1000,
    output_prealloc = $output_prealloc,
)

@benchmark calculate_conduction_map_vec(
    $adj_matrix,
    $times_sorted,
    $starts,
    1000,
    output_prealloc = $output_prealloc,
)
