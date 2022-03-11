using SparseArrays, Random
using DataFrames, CSV
using PlotlyJS
using Graphs, SimpleWeightedGraphs
using ProgressMeter

include("../ActivatedMeshes/ActivatedMeshes.jl")
using .ActivatedMeshes

include("../io/read_binary.jl")
include("../io/load_geom_data.jl")
include("../misc/load_things.jl")
include("edge_hopping.jl")
include("calculate_cv.jl")
include("intersections.jl")
include("baricenter.jl")
include("find_next_tetrahedron.jl")
include("find_nearest_times.jl")
include("plot_tetrahedron_edges.jl")

##

heart = 15
folders_try = [
    "/Volumes/Samsung_T5/Rheeda",
    "/media/andrey/Samsung_T5/Rheeda"
]
folder = folders_try[findfirst(isdir.(folders_try))]

filename_tetra = joinpath(folder, "M$heart/M$(heart)_IRC_tetra.int32")
tetra = read_binary(filename_tetra, Int32, (4, :))
tetra = permutedims(tetra, (2, 1))
tetra .+= 1

filename_points = joinpath(folder, "M$heart/M$(heart)_IRC_3Dpoints.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

filename_I_tetra = joinpath(folder, "M$heart/I_tetra.int32")
I_tetra = read_binary(filename_I_tetra, Int32)
filename_J_tetra = joinpath(folder, "M$heart/J_tetra.int32")
J_tetra = read_binary(filename_J_tetra, Int32)

A_tetra = sparse(I_tetra, J_tetra, trues(size(I_tetra)))

##

group = 2
stim = "17"

filename_times = joinpath(
    folder,
    "activation/data-light/M$heart/G$group/S$stim/times.float32"
)
times = read_binary(filename_times, Float32)

filename_starts = joinpath(
    folder,
    "activation/data-light/M$heart/G$group/S$stim/indices_start.int32"
)
starts = read_binary(filename_starts, Int32)

A_vertices = load_adj_matrix(joinpath(folder, "M$heart/adj_matrix"), false)

mesh = ActivatedMesh(A_vertices, A_tetra, tetra, starts, Dict(:times => times), Dict(:points => points))
