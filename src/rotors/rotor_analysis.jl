using ProgressMeter
using SparseArrays
using Graphs
using JSON
using DataFrames
using Statistics
using CSV

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("../conduction/collect_counts_n_sums.jl")
include("find_rotors.jl")
include("visit_breaks.jl")
include("create_arrays_subsets.jl")
include("structs.jl")

##

heart_ids = (13, 15)

adj_matrices = Dict(
    i_heart =>
        load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix")
    for i_heart in heart_ids
)

##

folder_root = "/media/andrey/easystore/Rheeda/activation/"

group_ids = 1:4
stim_ids = 0:39

df = DataFrame(
    heart = Int[],
    group = Int[],
    stim = Int[],
    # CL_crit=Float64[],
    # birthtime=Float64[],
    # lifetime=Float64[],
    birth_indices = Vector{Int}[],
)

for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids

    triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

    if !isfile(filename)
        continue
    end

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        continue
    end

    # @info triplet

    folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")

    act_times = ActivationTimes(
        convert.(Int, read_binary(filename_starts, Int32)),
        convert.(Float64, read_binary(filename_times, Float32)),
    )

    adj_matrix = adj_matrices[i_heart]

    for rotor in rotors
        indices_rotor = convert.(Int, rotor["indices_points"])

        act_times_rotor = create_act_times_subset(act_times, indices_rotor)
        act_graph_rotor =
            ActivatedGraph(act_times_rotor, adj_matrix[indices_rotor, indices_rotor])

        i_t_start = findfirst(act_graph_rotor.times .== rotor["t_start"])
        is_available = collect(act_graph_rotor.times .>= rotor["t_start"])
        is_visited = zeros(Bool, size(is_available))

        visit_breaks(
            i_t_start,
            act_graph = act_graph_rotor,
            is_available = is_available,
            is_visited = is_visited,
            dt_max = 20.0,
        )

        mean_diffs = zeros(length(act_graph_rotor.starts))
        CL_mean = 0.0

        for (i, (start, stop)) in
            enumerate(zip(act_graph_rotor.starts, act_graph_rotor.stops))
            mask = is_visited[start:stop]
            times = act_graph_rotor.times[start:stop][mask]
            for CL in diff(times)
                if !isnan(CL)
                    CL_mean = (CL_mean * (i - 1) + CL) / i
                end
            end
        end

        @show row = Dict(
            "heart" => i_heart,
            "group" => i_group,
            "stim" => i_stim,
            "CL_crit" => CL_mean,
            "birthtime" => rotor["t_start"],
            "lifetime" => rotor["lifetime"],
        )

        push!(df, row)

    end

end

##

CSV.write("../../data/rotors/M15-CL_crit.csv", df)


##


folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_root = "/media/andrey/Samsung_T5/Rheeda/activation/"

group_ids = 1:4
stim_ids = 0:39

group_ids = (1,)
stim_ids = (13,)
heart_ids = (13,)

df = DataFrame(heart = Int[], group = Int[], stim = Int[], birth_indices = Vector{Int}[])

for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids

    @show triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

    if !isfile(filename)
        continue
    end

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        continue
    end

    folder_data = joinpath(folder_root, "data-light", replace(triplet, '-' => '/'))
    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")

    act_times = ActivationTimes(
        convert.(Int, read_binary(filename_starts, Int32)),
        convert.(Float64, read_binary(filename_times, Float32)),
    )

    indices_native = 1:length(act_times.starts)

    for rotor in rotors
        indices_rotor = convert.(Int, rotor["indices_points"])

        # act_times_rotor = create_act_times_subset(act_times, indices_rotor)
        act_times_rotor = act_times  # REMOVE ME

        birthtime = rotor["t_start"]
        inittime = 10.0  # ms

        birth_indices_times =
            findall((birthtime .<= act_times_rotor.times .<= birthtime + inittime))

        birth_indices = Int[]
        # for i in birth_indices_times
        #     birth_index = searchsortedlast(act_times_rotor.starts, i)
        #     birth_index_native = indices_rotor[birth_index]
        #     push!(birth_indices, birth_index_native)
        # end

        row = Dict(
            "heart" => i_heart,
            "group" => i_group,
            "stim" => i_stim,
            "birth_indices" => birth_indices,
        )

        push!(df, row)

    end

    # break

end

##

CSV.write("../../data/rotors/birth_indices.csv", df)


##

heart_ids = (13, 15)
group_ids = 1: 4
stim_ids = 0: 39

adj_matrices = Dict(
    i_heart =>
        load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
    for i_heart in heart_ids
)

folder_root = "/media/andrey/easystore/Rheeda/activation/"

##

for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids

i_heart, i_group, i_stim = 13, 1, 28

triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
filename = joinpath("../../data/rotors/trajectories/", "$triplet.json")

rotors = JSON.parsefile(filename)
