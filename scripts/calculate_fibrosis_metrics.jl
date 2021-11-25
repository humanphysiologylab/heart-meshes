using Graphs, SimpleWeightedGraphs
using UnPack
using ProgressMeter

include("./load_files.jl")
include("../src/graph.jl")
include("../src/entropy.jl")

##
heart_id = 13
folder = joinpath("/media/andrey/ssd2/WORK/HPL/Data/rheeda/", "M$heart_id")

@unpack points, tetra, region_points, adj_matrix = load_files(folder)

axes_fibrosis = [1, 3] # map(x -> region_map[x], [32, 128])
mask_fibrosis = reduce(.|, eachrow(region_points[axes_fibrosis, :]))
indices_fibrosis = findall(mask_fibrosis)

##
g = SimpleWeightedGraph(adj_matrix)

##
n_points = size(points)[2]
n_samples = 100_000
radia = [1e4]

probas = calculate_FE_probas(adj_matrix .> 0.0, mask_fibrosis)

##
filename_metrics = joinpath(folder, "fibrosis_metrics.csv")

##

if !isfile(filename_metrics)
    @warn "Make header!"
    header_names = ["i", "r", "x", "y", "z", "n_total", "n_fibrosis", "fd", "fe"]
    header = join(header_names, ",")
    write(filename_metrics, header * "\n")
end

file_metrics = open(filename_metrics, "a");

@showprogress for i ∈ rand(1:n_points, n_samples), r ∈ radia

    neighbours = neighborhood(g, i, 1e4)

    mask_fibrosis_area = @view mask_fibrosis[neighbours]

    n_points_area = length(neighbours)
    n_points_fibrosis = sum(mask_fibrosis_area)

    fibrosis_density = n_points_fibrosis / n_points_area

    ps = @view probas[neighbours]
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
unique!(df_metrics)
df_metrics.i = convert.(Int, df_metrics.i)

# df_metrics_r = df_metrics[df_metrics.r.==5000, :]

##
ds = dijkstra_many_sourses(g, df_metrics.i)
nearest_src = ds.parents

columns = [:fd, :fe]

df_interp = DataFrame()
for c in columns
    v = sparsevec(df_metrics.i, df_metrics[!, c], n_points)
    df_interp[!, c] = v[nearest_src]
end

## 
filename_metrics_interp = joinpath(folder, "fibrosis_metrics_interp.csv")

writedlm(
    filename_metrics_interp,
    Iterators.flatten(([names(df_interp)], eachrow(df_interp))),
    ',',
)
