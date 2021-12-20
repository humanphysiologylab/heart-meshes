using ProgressMeter
using SparseArrays
using Graphs
using JSON

include("../io/read_binary.jl")
include("../misc/create_stops.jl")
include("../io/load_adj_matrix.jl")
include("../conduction/collect_counts_n_sums.jl")
include("find_rotors.jl")
include("visit_breaks.jl")
# include("../misc/pyplot.jl")
include("create_arrays_subsets.jl")
include("structs.jl")

##

i_heart = 15
adj_matrix = load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix")
adj_matrix = convert(SparseMatrixCSC{Bool,Int}, adj_matrix)

i_group = 1
t_threshold = 1000.0
dt_max = 20.0
component_size_min = 42
conduction_threshold = 0.95

folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_rotors = joinpath(folder_root, "rotors/jsons")

n_folders = 40
prog = Progress(n_folders)
generate_showvalues(iter, rotors) = () -> [(:iter, iter), (:n_rotors, rotors)]

for i_stim_number = 0:n_folders-1

    i_stim = string(i_stim_number, pad = 2)

    filename_save = joinpath(folder_rotors, "M$(i_heart)-G$(i_group)-S$(i_stim).json")

    if isfile(filename_save)
        @info "found: $filename_save"
        continue
    end

    triplet = "M$i_heart/G$i_group/S$i_stim"
    folder_data = joinpath(folder_root, "data-light", triplet)
    folder_results = joinpath(folder_root, "results", triplet)

    filename_times = joinpath(folder_data, "times.float32")
    filename_starts = joinpath(folder_data, "indices_start.int32")

    filename_conduction = joinpath(folder_results, "conduction.float32")

    filenames = filename_starts, filename_times, filename_conduction
    if !all(isfile.(filenames))
        @warn "incomplete root: $folder_data"
        continue
    end

    act_times = ActivationTimes(
        convert.(Int, read_binary(filename_starts, Int32)),
        convert.(Float64, read_binary(filename_times, Float32)),
    )

    conduction = convert.(Float64, read_binary(filename_conduction, Float32))
    conduction[act_times.stops] .= 1

    conduction_percent_sum, conduction_percent_count =
        collect_counts_n_sums(conduction, act_times.starts, act_times.stops)

    mask_nonzeros = .!iszero.(conduction_percent_count)

    conduction_percent_mean = zeros(size(conduction_percent_sum))
    conduction_percent_mean[mask_nonzeros] =
        conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

    indices_breaks = findall(conduction_percent_mean .< conduction_threshold)

    act_times_subset = create_act_times_subset(act_times, indices_breaks)
    adj_matrix_breaks = adj_matrix[indices_breaks, indices_breaks]
    cc = connected_components(SimpleGraph(adj_matrix_breaks))

    act_graphs = ActivatedGraph[]
    indices_breaks_connected = typeof(indices_breaks)[]

    for component in cc

        if length(component) < component_size_min
            continue
        end

        indices = indices_breaks[component]
        at = create_act_times_subset(act_times, indices)

        if length(at.times) == 0
            continue
        end

        push!(act_graphs, ActivatedGraph(at, adj_matrix[indices, indices]))
        push!(indices_breaks_connected, indices)

    end

    moving_breaks = find_moving_breaks(act_graphs, dt_max)

    rotors = []

    for (i, (ids, t_mins, t_maxs)) in enumerate(moving_breaks)

        lifetimes = t_maxs - t_mins
        lifetime_max, id_lifetime_max = findmax(lifetimes)

        if lifetime_max < t_threshold
            continue
        end

        indices_points = indices_breaks_connected[i]

        # indices_times_local = findall(ids .== id_lifetime_max)
        # times_indices = 1: length(act_times.times)
        # indices_times = times_indices[indices_times_local] 

        r = Dict(
            "lifetime" => lifetime_max,
            "t_start" => t_mins[id_lifetime_max],
            "indices_points" => indices_points,
        )
        @show i, lifetime_max, t_mins[id_lifetime_max]

        push!(rotors, r)

    end

    result = Dict("components" => indices_breaks_connected, "rotors" => rotors)

    write(filename_save, json(result))

    ProgressMeter.next!(
        prog;
        showvalues = generate_showvalues(i_stim_number, length(rotors)),
    )

end
