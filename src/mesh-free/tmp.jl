filename_times = "/Volumes/Samsung_T5/Rheeda/activation/data-light/M13/G1/S13/times.float32"
times = read_binary(filename_times, Float32)

filename_starts = "/Volumes/Samsung_T5/Rheeda/activation/data-light/M13/G1/S13/indices_start.int32"
starts = read_binary(filename_starts, Int32)

A_vertices = load_adj_matrix(joinpath(folder, "adj_matrix"), false)

include("../ActivatedMeshes/ActivatedMeshes.jl")
using .ActivatedMeshes

mesh = ActivatedMesh(A_vertices, A_tetra, tetra, starts, Dict(:times => times), Dict(:points => points))
