using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics

include("../src/graph.jl")
include("../src/entropy.jl")
include("../src/io.jl")

##
heart_id = 13
folder = joinpath("/media/andrey/easystore/Rheeda", "M$heart_id")
##

adj_matrix = load_adj_matrix(folder, false)
g = SimpleWeightedGraph(adj_matrix)

##

arrays = Dict{String, Vector}()

for i_group in 1:4,
    time_name in ("before", "after"),
    name in ("", "roman-")

    folder_conduction = "/media/andrey/easystore/Rheeda/activation/conduction-mean/"
    conduction_sum = read_binary(
        joinpath(folder_conduction, "M$heart_id-G$i_group-conduction-$(name)$(sum)-$time_name-2500-ms.float64"),
        Float64
    )
    conduction_count = read_binary(
        joinpath(folder_conduction, "M$heart_id-G$i_group-conduction-$(name)$(count)-$time_name-2500-ms.int64"),
        Int64
    )
    wavebreak_mean = @. 1. - conduction_sum / conduction_count
    @. wavebreak_mean[isnan(wavebreak_mean)] = 1.

    key = "wavebreaks-$(name)M$heart_id-G$i_group-$time_name"
    arrays[key] = wavebreak_mean

end
##
filename_region = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M13/M13_IRC_points_region.int"
region = read_binary(filename_region, Int)
fibrosis_ids = [32, 128]
mask_fibrosis = region .∈ Ref(fibrosis_ids)

arrays["fibrosis-density"] = mask_fibrosis

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

# filename_csv = joinpath(folder_save, "M13_wavebreaks_averaged_roman_srcs.csv")
data, header = readdlm(filename_csv, ',', Float64, header = true)

df = DataFrame(data, vec(header))
unique!(df)
df[!, vertex_id_column] = convert.(Int, df[!, vertex_id_column])

##
ds = dijkstra_many_sourses(g, df[!, vertex_id_column])
nearest_src = ds.parents

columns = header_names[2:end]

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
