using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("entropy.jl")

##
heart_id = 13

##
folder_data = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/"

folder = joinpath(folder_data, "M$heart_id", "adj_matrix")
adj_matrix = load_adj_matrix(folder, false)
g = SimpleWeightedGraph(adj_matrix)

##
filename_mask_fibrosis = joinpath(folder_data, "M$heart_id", "mask_fibrosis.bool")
mask_fibrosis = read_binary(filename_mask_fibrosis, Bool)

probas = calculate_FE_probas(adj_matrix .> 0.0, mask_fibrosis)

##
n_points = size(adj_matrix, 1)
n_samples = 10_000
samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]
# radia = [1e4]
r = 1e4

##

folder_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/metrics"
filename_csv = joinpath(folder_save, "latest.csv")
@assert isdir(folder_save)

##

vertex_id_column = "vertex_id"
columns_metric = "fibrosis-entropy"
header_names = [vertex_id_column, columns_metric]

if !isfile(filename_csv)
    @info "Create csv with header!"
    header = join(header_names, ",")
    write(filename_csv, header * "\n")
end

file_csv = open(filename_csv, "a");

@showprogress for vertex_id ∈ samples

    neighbours = neighborhood(g, vertex_id, r)
    n_points_area = length(neighbours)

    ps = @view probas[neighbours]
    fe = calculate_entropy(ps) / n_points_area

    write(file_csv, join(map(string, [vertex_id, fe]), ","))
    write(file_csv, "\n")
    flush(file_csv)

end

close(file_csv)

##
