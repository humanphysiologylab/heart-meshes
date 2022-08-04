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

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

heart = 15

folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)
g = SimpleWeightedGraph(A)

##

filename_fibrosis = joinpath(folder_rheeda, "geometry", "M$heart", "mask_fibrosis.bool")
mask_fibrosis = read_binary(filename_fibrosis, Bool)

indices_fibrosis = findall(mask_fibrosis)

ds = dijkstra_shortest_paths(g, indices_fibrosis)

dists = ds.dists

filename_save = joinpath(folder_rheeda, "geometry", "M$heart", "dist-to-fibrosis.float32")
write(filename_save, dists)
