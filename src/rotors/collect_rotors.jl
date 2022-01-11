using JSON
using ProgressMeter

include("../io/load_adj_matrix.jl")
include("./ActivatedGraphs.jl")
using .ActivatedGraphs

include("./visit_breaks.jl")
include("./fill_rotor_arrays.jl")

# using .ActivatedGraphs: find_vertex_id  # this is not exported

heart_ids = (13, 15)
group_ids = 1: 4
stim_ids = 0: 39

# p = Progress(*(length.([heart_ids, group_ids, stim_ids])...))
prog = ProgressUnknown("Collecting rotors:", spinner=true)

adj_matrices = Dict(
    i_heart =>
        load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
    for i_heart in heart_ids
)

folder_root = "/media/andrey/easystore/Rheeda/activation/"

##

for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids

    triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath("../../data/rotors/jsons/", "$triplet.json")
    filename_save = joinpath("../../data/rotors/trajectories/", "$triplet.json")

    if isfile(filename_save)
        @info "found: $filename_save"
        continue
    end

    if !isfile(filename)
        @info "not found: $filename"
        continue
    end

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        continue
    end

    folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
    folder_results = joinpath(folder_root, "results", replace(triplet, '-' => '/'))
    
    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")
    filename_conduction = joinpath(folder_results, "conduction.float32")
        
    adj_matrix = adj_matrices[i_heart]
    starts = read_binary(filename_starts, Int32)
    times = read_binary(filename_times, Float32)
    conduction = read_binary(filename_conduction, Float32)
        
    ag = ActivatedGraph(adj_matrix, starts, Dict(:times => times, :conduction => conduction))

    result = []
    
    for (i_rotor, rotor) in enumerate(rotors)

        ProgressMeter.next!(prog)

        indices_rotor = convert.(Int, rotor["indices_points"])
        ag_rotor = ActivatedGraphs.induced_subgraph(ag, indices_rotor)
        fill_rotor_arrays!(ag_rotor)

        lifetime_max, i = findmax(ag_rotor[:lifetime])

        vertex_ids = ag_rotor.type_array[]
        times_ids = ag_rotor.type_array[]
        times = eltype(ag_rotor[:times])[]

        while i ≠ -1
            v = find_vertex_id(ag_rotor, i)
            push!(vertex_ids, v)
            push!(times_ids, i)
            push!(times, ag_rotor[:times][i])
            i = ag_rotor[:parents][i]
        end

        indices_sort = sortperm(times)

        times = times[indices_sort]
        times_ids = times_ids[indices_sort]
        vertex_ids = vertex_ids[indices_sort]

        vertex_ids_native = indices_rotor[vertex_ids]

        push!(
            result,
            Dict(
                "times" => times,
                "vertex_ids" => vertex_ids_native,
                "times_ids" => times_ids
            )
        )

    end

    write(filename_save, json(result))

    # break

end

ProgressMeter.finish!(prog)

##
