using PyPlot
using PyCall
pygui(true)

##
include("load_src.jl")

##
include("load_files.jl")

##
using NearestNeighbors: BallTree
btree = BallTree(points; leafsize = 30, reorder = false)

##
index_center = 850_000
radius = 1e4

k, v = find_area(index_center, radius, points, S, btree)

argsort = sortperm(v)
v = v[argsort]
k = k[argsort]

##
(ix, iy, iz) = (1, 3, 2)
stride = 10

scatter(
    points[ix, 1:stride:end],
    points[iy, 1:stride:end],
    c = points[iz, 1:stride:end],
    # cmap="BuPu",
    marker = ",",
    s = 4,
    alpha = 0.01,
    zorder = -1,
)

##

n_points = size(points)[2]
components_colors = color_connected_components(components, n_points)

n_colors = 3

mask_largest = 0 .< components_colors .<= n_colors
colors_largest = components_colors[mask_largest]

scatter(
    points[ix, mask_largest],
    points[iy, mask_largest],
    c = colors_largest,
    cmap = "tab10",
    marker = ",",
    s = 1,
    # alpha=0.1,
    # zorder=-1
)

##
scatter(
    points[ix, k][1:10:end],
    points[iy, k][1:10:end],
    c = v[1:10:end],
    s = 4,
    cmap = "viridis",
)

plot(points[ix, index_center], points[iy, index_center], "*", color = "C3")

axis("equal")

##
stride = 10

scatter(
    points[ix, 1:stride:end],
    points[iy, 1:stride:end],
    c = region_points[1:stride:end],
    cmap = "tab10",
    marker = ",",
    s = 4,
    alpha = 0.01,
    zorder = -1,
)
