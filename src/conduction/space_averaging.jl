using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics
using OrderedCollections

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

disk_name = "Samsung_T5"

##
heart_id = 13

folder = joinpath("/media/andrey/ssd2/WORK/HPL/Data/rheeda", "M$heart_id", "adj_matrix")
adj_matrix = load_adj_matrix(folder, false)
g = SimpleWeightedGraph(adj_matrix)

##
arrays = Dict{String,Vector}()

##

multi_index = OrderedDict(
    "group" => 1:4,
    "period" => ("before", "after"),
    "method" => ("percent", "binary"),
    "counts" => ("activation", "transmission")
)

for index_values in Iterators.product(values(multi_index)...)

    i_group, period, method, counts = index_values

    folder_conduction = joinpath(
        "/media/andrey", 
        disk_name,
        "Rheeda/activation/conduction-mean/"
    )

    counts_name = (counts == "transmission") ? "sum" : "count"
    ext = (counts == "transmission") ? ".float64" : ".int64"
    type = (counts == "transmission") ? Float64 : Int

    data = read_binary(
        joinpath(
            folder_conduction,
            "M$heart_id-G$i_group-conduction-$method-$counts_name-$period-2500-ms$ext",
        ),
        type,
    )

    # wavebreak_mean = @. 1.0 - conduction_sum / conduction_count
    # @. wavebreak_mean[isnan(wavebreak_mean)] = 1.0

    key = "M$heart_id-G$i_group-$period-$method-$counts"
    arrays[key] = data

end

##

multi_index = OrderedDict(
    "group" => 1:4,
    "period" => ("before", "after"),
    "method" => ("percent", "binary"),
    # "counts" => ("activation", "transmission")
)

for index_values in Iterators.product(values(multi_index)...)

    i_group, period, method = index_values

    key_numerator = "M$heart_id-G$i_group-$period-$method-transmission"
    key_denominator = "M$heart_id-G$i_group-$period-$method-activation"

    key_result = "M$heart_id-G$i_group-$period-$method-ratio"

    arrays[key_result] = arrays[key_numerator] ./ arrays[key_denominator]

end


##
filename_mask_fibrosis =
    joinpath("/media/andrey", disk_name, "Rheeda", "M$heart_id", "mask_fibrosis.bool")
arrays["fibrosis-density"] = read_binary(filename_mask_fibrosis, Bool)

##
n_points = size(adj_matrix, 1)
n_samples = 100_000
samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]
# radia = [1e4]
r = 1e4
##

folder_save = joinpath("/media/andrey", disk_name, "Rheeda/activation/wavebreaks-averaged")
filename_csv = joinpath(folder_save, "latest.csv")

##

vertex_id_column = "vertex_id"
header_names = [vertex_id_column, collect(keys(arrays))...]

if true # !isfile(filename_csv)
    @info "Create csv with header!"
    header = join(header_names, ",")
    write(filename_csv, header * "\n")
end

file_csv = open(filename_csv, "a");
# file_csv = open(filename_csv, "w");

@showprogress for vertex_id ∈ samples

    neighbours = neighborhood(g, vertex_id, r)
    n_points_area = length(neighbours)

    write(file_csv, string(vertex_id))

    for (i, (key, value)) in enumerate(arrays)
        x = mean(value[neighbours])
        write(file_csv, "," * string(x))

        # for p in 0: 0.25: 1
        #     x = quantile(value[neighbours], p)
        #     write(file_csv, "," * string(x))
        # end

    end

    write(file_csv, "\n")
    flush(file_csv)

end

close(file_csv)

##
using DelimitedFiles, DataFrames

folder_save = "../../data/rotors/"
# filename_csv = joinpath(folder_save, "M13-all-r1e4-srcs.csv")
filename_csv = joinpath(folder_save, "M13-FE-r1e4-srcs.csv")

data, header = readdlm(filename_csv, ',', Float64, header = true)

df = DataFrame(data, vec(header))
unique!(df)

vertex_id_column = :vertex_id
df[!, vertex_id_column] = convert.(Int, df[!, vertex_id_column])
##

using CSV

# df = DataFrame(CSV.File("../../data/rotors/M13-FE-r1e4-srcs.csv"))

##

filename_load = "../../data/space_averaging/M15.csv"
df = DataFrame(CSV.File(filename_load))
vertex_id_column = :vertex_id

##
# ds = dijkstra_many_sourses(g, df[!, vertex_id_column])
ds = dijkstra_many_sourses(ag.graph, df[!, vertex_id_column])

nearest_src = ds.parents

columns = ("fibrosis-density",)
# columns = header[2:end]
n_points = nv(ag.graph)

## 

df_interp = DataFrame()
for c in columns
    v = sparsevec(df[!, vertex_id_column], df[!, c], n_points)
    df_interp[!, c] = v[nearest_src]
end

## 

filename_interp_save = "../../data/space_averaging/M15_fd_interp.csv"
# filename_interp_csv = joinpath(folder_save, "latest_interp.csv")

# CSV.write(filename_interp_save, df_interp)

##

writedlm(
    filename_interp_csv,
    Iterators.flatten(([names(df_interp)], eachrow(df_interp))),
    ',',
)
