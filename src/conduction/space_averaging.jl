using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

##
heart_id = 15
##

folder = joinpath("/media/andrey/easystore/Rheeda", "M$heart_id", "adj_matrix")
adj_matrix = load_adj_matrix(folder, false)
g = SimpleWeightedGraph(adj_matrix)

##

using OrderedCollections

arrays = Dict{String, Vector}()

multi_index = OrderedDict(
    "group" => 1:4,
    "period" => ("before", "after"),
    "method" => ("percent", "binary")
)

for index_values in Iterators.product(values(multi_index)...)
    
    i_group, period, method = index_values

    folder_conduction = "/media/andrey/easystore/Rheeda/activation/conduction-mean/"
    conduction_sum = read_binary(
        joinpath(folder_conduction, "M$heart_id-G$i_group-conduction-$method-$sum-$period-2500-ms.float64"),
        Float64
    )
    conduction_count = read_binary(
        joinpath(folder_conduction, "M$heart_id-G$i_group-conduction-$method-$count-$period-2500-ms.int64"),
        Int64
    )
    wavebreak_mean = @. 1. - conduction_sum / conduction_count
    @. wavebreak_mean[isnan(wavebreak_mean)] = 1.

    key = "wavebreaks-M$heart_id-G$i_group-$period-$method"
    arrays[key] = wavebreak_mean

end

##
filename_mask_fibrosis = joinpath("/media/andrey/easystore/Rheeda", "M$heart_id", "mask_fibrosis.bool")
arrays["fibrosis-density"] = read_binary(filename_mask_fibrosis, Bool)

##
n_points = size(adj_matrix, 1)
n_samples = 10_000
samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]
# radia = [1e4]
r = 1e4
##

folder_save = "/media/andrey/easystore/Rheeda/activation/wavebreaks-averaged"
filename_csv = joinpath(folder_save, "latest.csv")

##

vertex_id_column = "vertex_id"
header_names = [vertex_id_column, collect(keys(arrays))...]

if !isfile(filename_csv)
    @info "Create csv with header!"
    header = join(header_names, ",")
    write(filename_csv, header * "\n")
end

file_csv = open(filename_csv, "a");

@showprogress for vertex_id ∈ samples

    neighbours = neighborhood(g, vertex_id, r)
    n_points_area = length(neighbours)

    write(file_csv, string(vertex_id))

    for (i, (key, value)) in enumerate(arrays)
        x = mean(value[neighbours])
        write(file_csv, "," * string(x))
    end

    write(file_csv, "\n")
    flush(file_csv)

end

close(file_csv)

##
using DelimitedFiles, DataFrames

# filename_csv = joinpath(folder_save, "M15-all-r1e4-srcs.csv")
data, header = readdlm(filename_csv, ',', Float64, header = true)

df = DataFrame(data, vec(header))
unique!(df)
df[!, vertex_id_column] = convert.(Int, df[!, vertex_id_column])

##
ds = dijkstra_many_sourses(g, df[!, vertex_id_column])
nearest_src = ds.parents

columns = header[2:end]

df_interp = DataFrame()
for c in columns
    v = sparsevec(
        df[!, vertex_id_column],
        df[!, c],
        n_points
    )
    df_interp[!, c] = v[nearest_src]
end

## 
filename_interp_csv = joinpath(folder_save, "latest_interp.csv")

writedlm(
    filename_interp_csv,
    Iterators.flatten(([names(df_interp)], eachrow(df_interp))),
    ',',
)
