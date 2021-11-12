include("load_src.jl")

##
include("load_files.jl")

##
axes_fibrosis = [1, 3] # map(x -> region_map[x], [32, 128])
mask_fibrosis = reduce(.|, eachrow(region_points[axes_fibrosis, :]))
indices_fibrosis = findall(mask_fibrosis)

##
using NearestNeighbors
btree = BallTree(points; leafsize = 30, reorder = false)

##

n_points = size(points)[2]
n_samples = 10_000
radia = 1e3, 2.5e3, 5e3

probas = calculate_FE_probas(S, mask_fibrosis)[:, 1]
probas_vec = sparsevec(findall(mask_fibrosis), probas, length(mask_fibrosis))

##

using ProgressMeter

filename_metrics = "fibrosis_metrics.csv"
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

using DelimitedFiles, DataFrames

metrics, header = readdlm(filename_metrics, ',', Float64, '\n', header = true)

df_metrics = DataFrame(metrics, vec(header))
df_metrics.i = convert.(Int, df_metrics.i)

df_metrics_r = df_metrics[df_metrics.r.==5000, :]

##

indices_saved = unique(convert.(Int, metrics[:, 1]))
indices_interp = setdiff(indices_fibrosis, indices_saved)

points_fibrosis = points[:, mask_fibrosis]

points_fibrosis_saved = points[:, indices_saved]
points_fibrosis_interp = points[:, indices_interp]

kdtree = KDTree(points_fibrosis_saved; reorder = false)
idxs, dists = nn(kdtree, points_fibrosis)

idxs_native = indices_saved[idxs]

columns = [:fd, :fe]

metric_interp =
    [df_metrics_r[findfirst(df_metrics_r.i .== i), columns] for i in idxs_native]
df_interp = DataFrame(transpose(hcat(collect.(metric_interp)...)), columns)
df_interp.i = indices_fibrosis
sort!(df_interp, [:i])

writedlm(
    "fibrosis_metrics_interp.csv",
    Iterators.flatten(([names(df_interp)], eachrow(df_interp))),
    ',',
)
