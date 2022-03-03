using JSON
using ProgressMeter

include("../io/load_adj_matrix.jl")
include("./ActivatedGraphs.jl")
using .ActivatedGraphs

include("./fill_rotor_arrays.jl")
include("./extend_area.jl")

# using .ActivatedGraphs: find_vertex_id  # this is not exported

heart_ids = (13, 15)
group_ids = 1: 4
stim_ids = 0: 39

# p = Progress(*(length.([heart_ids, group_ids, stim_ids])...))

adj_matrices = Dict(
    i_heart =>
        load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
    for i_heart in heart_ids
)

# folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_root = "/media/andrey/Samsung_T5/Rheeda/activation/"

##

function create_ag(;triplet, folder_root, adj_matrix)

    folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
    folder_results = joinpath(folder_root, "results", replace(triplet, '-' => '/'))
    
    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")
    filename_conduction = joinpath(folder_results, "conduction.float32")
        
    starts = read_binary(filename_starts, Int32)
    times = read_binary(filename_times, Float32)
    conduction = read_binary(filename_conduction, Float32)
        
    ag = ActivatedGraph(adj_matrix, starts, Dict(:times => times, :conduction => conduction))

end

##

for i_heart in heart_ids, i_group in group_ids

    adj_matrix = adj_matrices[i_heart]

    for i_stim in stim_ids

        triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"

        filename_save = joinpath("../../data/rotors/trajectories/", "$triplet.json")
        if isfile(filename_save)
            @info "found: $filename_save"
            continue
        end

        filename = joinpath("../../data/rotors/jsons/", "$triplet.json")
        if !isfile(filename)
            @info "not found: $filename"
            continue
        end
        wavebreaks = JSON.parsefile(filename)
        rotors = wavebreaks["rotors"]

        if length(rotors) < 1
            continue
        end

        ag = create_ag(;triplet, folder_root, adj_matrix)

        result = []
        
        for (i_rotor, rotor) in enumerate(rotors)

            indices_rotor = convert.(Int, rotor["indices_points"])
            indices_rotor_extended = extend_area(ag.graph, indices_rotor, 2000.)
            ag_rotor = ActivatedGraphs.induced_subgraph(ag, indices_rotor_extended)
            ag_rotor[:is_available] = ag_rotor[:times] .> 2500.

            @info "start: $triplet $i_rotor"
            summary_info = fill_rotor_arrays!(ag_rotor)

            summary_info_filtered = filter(
                x -> x[:lifetime_max] > 500.,
                summary_info
            )

            if isempty(summary_info_filtered)
                @warn "no rotors > 1000 ms found: $triplet"
                continue
            end

            for rotor_info in summary_info_filtered

                @info "Next rotor:\n$rotor_info"

                vertex_ids = ag_rotor.type_array[]
                times_ids = ag_rotor.type_array[]

                i = rotor_info[:index_times_finish]

                while i ≠ -1
                    v = find_vertex_id(ag_rotor, i)
                    push!(vertex_ids, v)
                    push!(times_ids, i)
                    i = ag_rotor[:parents][i]
                end

                times = ag_rotor[:times][times_ids]
                vertex_ids_native = indices_rotor_extended[vertex_ids]

                push!(
                    result,
                    Dict(
                        "times" => times,
                        "vertex_ids" => vertex_ids_native,
                        "times_ids" => times_ids,
                        "info" => rotor_info
                    )
                )
            
            end

        end

        write(filename_save, json(result))

    end  #stim

end

##
