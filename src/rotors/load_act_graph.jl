using JSON

include("../io/read_binary.jl")

function load_act_graph(
    i_heart,
    i_group,
    i_stim;
    folder_bin = "/media/andrey/easystore/Rheeda/activation/",
    folder_json = "../../data/rotors/jsons/",
)

    triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath(folder_json, "$triplet.json")

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        return nothing
    end

    folder_data = joinpath(folder_bin, "data-light", replace(triplet, '-' => '/'))
    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")

    act_times = ActivationTimes(
        convert.(Int, read_binary(filename_starts, Int32)),
        convert.(Float64, read_binary(filename_times, Float32)),
    )

    result = []

    for rotor in rotors
        indices_rotor = convert.(Int, rotor["indices_points"])

        act_times_rotor = create_act_times_subset(act_times, indices_rotor)
        act_graph_rotor =
            ActivatedGraph(act_times_rotor, adj_matrix[indices_rotor, indices_rotor])

        push!(result, act_graph_rotor)

    end

    result

end
