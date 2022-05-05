using SparseArrays, Random
using DataFrames, CSV
# using Graphs, SimpleWeightedGraphs
using ProgressMeter


include("../ActivatedMeshes/ActivatedMeshes.jl")
include("../ActArrays/ActArrays.jl")

include("../io/read_binary.jl")
include("../io/load_geom_data.jl")
include("../io/load_things.jl")

include("plot_tetrahedron_edges.jl")
include("plotly_helpers.jl")

include("../rotors/extend_area.jl")

include("run_gradient_descent.jl")
include("bfs.jl")

include("../io/load_arrays.jl")

##

heart = 15
disk_path = "samsung-T5/HPL/Rheeda"
folders_try = [
    joinpath("/Volumes", disk_path),
    joinpath("/media/andrey", disk_path)
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

A_vertices = load_adj_matrix(joinpath(folder, "M$heart/adj_matrix"), false)

A_tetra = sparse(I_tetra, J_tetra, ones(size(I_tetra)))
A_tetra.nzval .= 1

##

group = 3
stim = "37"

# filename_times = joinpath(
#     folder,
#     "data-light/M$heart/G$group/S$stim/times.float32"
# )
# times = read_binary(filename_times, Float32)

# filename_times = joinpath(
#     folder,
#     "data-light/M$heart/G$group/S$stim/conduction.float32"
# )
# times = read_binary(filename_times, Float32)

# filename_starts = joinpath(
#     folder,
#     "data-light/M$heart/G$group/S$stim/indices_start.int32"
# )
# starts = read_binary(filename_starts, Int32)

# a = ActArray(starts, Dict(:times => times))

##

a = load_arrays(heart, group, parse(Int, stim); folder_rheeda=folder)

mesh = ActivatedMesh(A_vertices, A_tetra, tetra, a, Dict(:points => points))

##

point2element = [Int[] for i in 1:size(points, 1)]

@showprogress for (i_element, element) in enumerate(eachrow(tetra))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end
