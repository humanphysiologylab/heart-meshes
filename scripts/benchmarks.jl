using BenchmarkTools

leafsize = 30
radius = 1e4

@benchmark BallTree(points; leafsize = leafsize, reorder = false)
btree = BallTree(points; leafsize = leafsize, reorder = false)

@benchmark find_ball(index_center, radius, points, S, btree)
