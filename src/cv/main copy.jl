include("../rotors/ActivatedGraphs.jl")
include("../misc/load_things.jl")
include("../rotors/extend_area.jl")

using JSON3
using DataFrames, CSV
using UnicodePlots

using .ActivatedGraphs

include("find_trajectory.jl")

##

i_heart = 15

folder_heart = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/"

folder_adj_matrix = joinpath(folder_heart, "M$i_heart", "adj_matrix")
adj_matrix = load_adj_matrix(folder_adj_matrix, false)

##

points = load_points(i_heart)

##

folder_jsons = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor_CL_cc"
folder_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/rotor-trajectory-feb22"

for filename_json in readdir(folder_jsons, join=true)

    rotor = JSON3.read(read(filename_json, String))
    heart = rotor[:heart]
    if heart ≠ i_heart
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

    # ag = load_activated_graph((i_heart, i_group, i_stim); adj_matrix)

    ag = nothing

    try
        ag = load_activated_graph((i_heart, i_group, i_stim); adj_matrix)
    catch e
        @warn "loading failed: $e"
        continue
    end

    ag.scalars[:points] = points

    vertex_ids = rotor[:vertices]
    vertices_unique = unique(vertex_ids)

    # times_rotor_last = ag[:times][ag.stops[vertices_unique]]
    # vertex_last = vertices_unique[findmax(times_rotor_last)[2]]
    # vertices_ids[findmax(times_rotor)[2]]

    # indices_area = extend_area(ag.graph, vertices_unique, 1e3)
    # i = indices_area[findmax(ag[:times][indices_area])[2]]

    indices_times_last = ag.stops[vertices_unique]
    times_last = ag[:times][indices_times_last]
    time_last, index_time_last = findmax(times_last)
    i = indices_times_last[index_time_last]

    @show i, time_last

    trajectory = find_trajectory(i, g=ag, ∇t_max=0.1)
    vertices = [find_vertex_id(ag, i) for i in trajectory]
    X = ag[:points][vertices, :]

    times = ag[:times][trajectory]

    result = Dict(zip(["x", "y", "z"], eachcol(X)))
    result["t"] = times
    result["v"] = vertices
    result["i_t"] = trajectory

    df = DataFrame(result)
    CSV.write(filename_save, df)

    # break

end
