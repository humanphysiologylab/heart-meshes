using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics
using OrderedCollections
using DataFrames, CSV

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

##

# heart  group
# 13     1        0
#        2        0
#        3        0
#        4        0
# 15     1        0
#        2        8
#        3        6
#        4        4
n_broken_stims = Dict(
    13 => [0, 0, 0, 0],
    15 => [0, 8, 6, 4]
)

##

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

heart = 15

folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)
g = SimpleWeightedGraph(A)

##

folder_conduction = joinpath(
    folder_rheeda,
    "conduction-cumulative"
)

arrays = Dict{Int, Dict{Symbol, Vector}}()

for group in 1: 4

    tag = "M$heart-G$group"

    filename_transmission = joinpath(folder_conduction, "transmission-$tag.int32")
    filename_activation = joinpath(folder_conduction, "activation-$tag.int32")

    transmission = read_binary(filename_transmission, Int32)
    activation = read_binary(filename_activation, Int32)

    @assert (activation .>= transmission) |> all
    @assert iszero.(transmission[iszero.(activation)]) |> all 

    arrays[group] = Dict(
        :transmission => transmission,
        :activation => activation,
    )

end

##

filename_mask_fibrosis = joinpath(folder_rheeda, "geometry", "M$heart", "mask_fibrosis.bool")
fd = read_binary(filename_mask_fibrosis, Bool)

##

n_points = size(A, 1)
n_samples = 10_000
samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]
r = 1e4

rows = []

groups = 1: 4
n_groups = length(groups)
append!(rows, fill(missing, n_samples * n_groups))

Threads.@threads for (i, vertex_id) ∈ collect(enumerate(samples))

    neighbours = neighborhood(g, vertex_id, r)
    n_points_area = length(neighbours)

    mean_fd = mean(fd[neighbours])

    for group in groups
        
        trans = arrays[group][:transmission][neighbours]
        act = arrays[group][:activation][neighbours]

        wb_proba = 1 - sum(trans) / sum(act)

        row = Dict(
            :i => vertex_id,
            :heart => heart,
            :group => group,
            :mean_trans => mean(trans),
            :mean_act => mean(act),
            :wb_proba => wb_proba,
            :mean_fd => mean_fd
        )

        rows[(i - 1) * n_groups + group] = row

    end

end

df = DataFrame(rows)

##

folder_save = joinpath(folder_rheeda, "averaging")
filename_csv = joinpath(folder_save, "M$heart-$n_samples-latest.csv")

CSV.write(filename_csv, df)
