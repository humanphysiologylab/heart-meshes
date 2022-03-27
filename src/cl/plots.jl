using PlotlyJS

##
filename_points = joinpath(folder_rheeda, "geometry/M$heart/points.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

##

c = cc[findmax(length.(cc))[2]]
d = dijkstra_shortest_paths(g, c)

##

step = 1000
trace_dist = scatter3d(;
    x = points[1: step: end, 1],
    y = points[1: step: end, 2],
    z = points[1: step: end, 3],
    mode = "markers",
    # marker_color = d.dists[1: step : end],
    marker_size = 1
)

##

trace = scatter3d(;
    x = points[c, 1],
    y = points[c, 2],
    z = points[c, 3],
    mode = "markers",
    # marker_color = d.dists[c],
    marker_size = 2
)

##

n_draw = 10
cc_draw = take(cc, n_draw)
cc_draw_flatten = cc_draw |> Iterators.flatten |> collect

color = [fill(i, length(c)) for (i, c) in enumerate(cc_draw)] |> Iterators.flatten |> collect

trace_components = scatter3d(;
    x = points[cc_draw_flatten, 1],
    y = points[cc_draw_flatten, 2],
    z = points[cc_draw_flatten, 3],
    mode = "markers",
    marker_color = color,
    marker_size = 1
)

##

plot([trace_dist, trace_components])
