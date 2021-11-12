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
index_center = 450_000
radius = 1e4

k, v = find_area(index_center, radius, points, S, btree)

argsort = sortperm(v)
v = v[argsort]
k = k[argsort]

##

axes_fibrosis = [1, 3] # map(x -> region_map[x], [32, 128])
mask_fibrosis = reduce(.|, eachrow(region_points[axes_fibrosis, :]))
indices_fibrosis = findall(mask_fibrosis)

##

n_points = size(points)[2]
n_samples = 10_000
radia = 1e3, 2.5e3, 5e3

probas = calculate_FE_probas(S, mask_fibrosis)[:, 1]
probas_vec = sparsevec(findall(mask_fibrosis), probas, length(mask_fibrosis))

##

using ProgressMeter

filename_metrics = "fibrosis_metrics_fixed.csv"
file_metrics = open(filename_metrics, "a");

@showprogress for i ∈ rand(indices_fibrosis, n_samples), r ∈ radia

    indices_area = find_area(i, r, points, S, btree)[1]

    mask_fibrosis_area = mask_fibrosis[indices_area]

    n_points_area = length(indices_area)
    n_points_fibrosis = sum(mask_fibrosis_area)

    fibrosis_density = n_points_fibrosis / n_points_area

    ps = nonzeros(probas_vec[indices_area])
    fibrosis_entropy = calculate_entropy(ps) / length(ps)

    values_save = i,
    r,
    points[:, i]...,
    n_points_area,
    n_points_fibrosis,
    fibrosis_density,
    fibrosis_entropy
    strings = map(string, values_save)
    result_line = join(strings, ",")

    write(file_metrics, result_line * "\n")
    flush(file_metrics)
end

close(file_metrics)

##
using DelimitedFiles
metrics = readdlm(filename_metrics, ',', Float64, '\n', skipstart = 1)

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

##

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
