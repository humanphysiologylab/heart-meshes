using SparseArrays
using Graphs, SimpleWeightedGraphs
using ProgressMeter
using JSON3
using DataFrames, CSV

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("run_gradient_descent.jl")

include("../ActivatedGraphs/ActivatedGraphs.jl")
using .ActivatedGraphs

include("../ActivatedMeshes/ActivatedMeshes.jl")
using .ActivatedMeshes

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

A_tetra = sparse(I_tetra, J_tetra, ones(size(I_tetra)))
A_tetra.nzval .= 1

A_vertices = load_adj_matrix(joinpath(folder, "M$heart/adj_matrix"), false)

##

point2element = [Int[] for i in 1:size(points, 1)]

@showprogress for (i_element, element) in enumerate(eachrow(tetra))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end

##

function load_mesh(heart, group, stim; A_vertices, A_tetra, tetra, points)

    stim = string(stim, pad = 2)

    filename_times = joinpath(
        folder,
        "data-light/M$heart/G$group/S$stim/times.float32"
    )
    times = read_binary(filename_times, Float32)

    filename_starts = joinpath(
        folder,
        "data-light/M$heart/G$group/S$stim/indices_start.int32"
    )
    starts = read_binary(filename_starts, Int32)

    mesh = ActivatedMesh(A_vertices, A_tetra, tetra, starts, Dict(:times => times), Dict(:points => points))

end

##

folder_jsons = joinpath(folder, "data/rotor_CL_cc")
folder_save = joinpath(folder, "data/rotor-trajectory-mar21")

for filename_json in readdir(folder_jsons, join=true)

    @show filename_json
    rotor = JSON3.read(read(filename_json, String))
    i_heart = rotor[:heart]
    if i_heart ≠ heart
        continue
    end

    i_group = rotor[:group]
    i_stim = rotor[:stim]
    i_rotor = rotor[:rotor]

    filename_body = splitdir(filename_json)[2]
    filename_body = split(filename_body, ".")[1]
    filename_save = joinpath(folder_save, filename_body * ".csv")

    if isfile(filename_save)
        continue
    end

    @show i_heart, i_group, i_stim

    # break

    # ag = load_activated_graph((i_heart, i_group, i_stim); adj_matrix)
    # ag = nothing

    mesh = nothing

    try  # soft local scope
        mesh = load_mesh(i_heart, i_group, i_stim; A_vertices, A_tetra, tetra, points)
    catch e
        @warn "loading failed: $e"
        continue
    end

    # vertex_ids = rotor[:vertices]
    # vertices_unique = unique(vertex_ids)

    # times_rotor_last = ag[:times][ag.stops[vertices_unique]]
    # vertex_last = vertices_unique[findmax(times_rotor_last)[2]]
    # vertices_ids[findmax(times_rotor)[2]]

    # indices_area = extend_area(ag.graph, vertices_unique, 1e3)
    # i = indices_area[findmax(ag[:times][indices_area])[2]]

    # indices_times_last = mesh.stops[vertices_unique]
    # times_last = mesh[:times][indices_times_last]
    # time_last, index_time_last = findmax(times_last)
    # index_vertex = indices_times_last[index_time_last]

    vertex_start = rotor[:vertices] |> first
    tetrahedron_start = point2element[vertex_start] |> first

    # @show tetrahedron_start, time_last

    df = run_gradient_descent(mesh, tetrahedron_start, step=-100, strategy=:random)
    @show df.t |> last
    CSV.write(filename_save, df)

    # break

end
