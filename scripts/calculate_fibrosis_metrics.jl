n_points = size(points)[2]
n_samples = 10_000
radia = [5e3]

probas = calculate_FE_probas(S, mask_fibrosis)

##
filename_metrics = joinpath(folder, "fibrosis_metrics_all_regions.csv")

##
using ProgressMeter

if !isfile(filename_metrics)
    header_names = ["i", "r", "x", "y", "z", "n_total", "n_fibrosis", "fd", "fe"]
    header = join(header_names, ",")
    write(filename_metrics, header * "\n")
end

file_metrics = open(filename_metrics, "a");

@showprogress for i ∈ rand(1:n_points, n_samples), r ∈ radia

    indices_area = find_area(i, r, points, S, btree)[1]

    mask_fibrosis_area = mask_fibrosis[indices_area]

    n_points_area = length(indices_area)
    n_points_fibrosis = sum(mask_fibrosis_area)

    fibrosis_density = n_points_fibrosis / n_points_area

    ps = probas[indices_area]
    fibrosis_entropy = calculate_entropy(ps) / n_points_area

    values_save = (
        i,
        r,
        points[:, i]...,
        n_points_area,
        n_points_fibrosis,
        fibrosis_density,
        fibrosis_entropy,
    )

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
using NearestNeighbors

indices_saved = unique(convert.(Int, metrics[:, 1]))
indices_interp = setdiff(1:n_points, indices_saved)

kdtree = KDTree(points[:, indices_saved]; reorder = false)
idxs, dists = nn(kdtree, points)
idxs_native = indices_saved[idxs]

columns = [:fd, :fe]

metric_interp =
    [df_metrics_r[findfirst(df_metrics_r.i .== i), columns] for i in idxs_native]

df_interp = DataFrame(transpose(hcat(collect.(metric_interp)...)), columns)
df_interp.i = 1:n_points

sort!(df_interp, [:i])

## 
filename_metrics_interp = joinpath(folder, "fibrosis_metrics_interp_all_regions.csv")

writedlm(
    filename_metrics_interp,
    Iterators.flatten(([names(df_interp)], eachrow(df_interp))),
    ',',
)
