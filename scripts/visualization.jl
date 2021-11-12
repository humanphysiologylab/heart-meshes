using PyPlot
using PyCall
pygui(true)

##
(ix, iy, iz) = circshift([1, 2, 3], 2)
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
scatter(
    metrics[:, ix+1],
    metrics[:, iy+1],
    c = metrics[:, 6],
    cmap = "RdYlBu_r",
    s = 4,
    alpha = 0.5,
)

##

points_fibro = points[:, mask_fibrosis]
# stride = 1
scatter(
    points_fibro[ix, 1:stride:end],
    points_fibro[iy, 1:stride:end],
    c = "r", # points_fibro[iz, 1:stride:end],
    # cmap="BuPu",
    marker = "o",
    s = 1,
    alpha = 0.1,
    zorder = -1,
)


components = load_connected_components(32, folder)

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
    alpha = 0.1,
    # zorder=-1
)

##
stride = 10
scatter(
    reverse(points[ix, k][1:stride:end]),
    reverse(points[iy, k][1:stride:end]),
    c = reverse(v[1:stride:end]),
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
