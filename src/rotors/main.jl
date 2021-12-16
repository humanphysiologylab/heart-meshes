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
i_heart = 13
adj_matrix = load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix")

##
i_group = 1
i_stim = string(13, pad = 2)

##
triplet = "M$i_heart/G$i_group/S$i_stim"
folder_root = "/media/andrey/easystore/Rheeda/activation/"
folder_data = joinpath(folder_root, "data-light", triplet)
folder_results = joinpath(folder_root, "results", triplet)
folder_rotors = joinpath(folder_root, "rotors", triplet)
mkpath(folder_rotors)

##
filename_times = joinpath(folder_data, "times.float32")
filename_starts = joinpath(folder_data, "indices_start.int32")

filename_conduction = joinpath(folder_results, "conduction.float32")

filenames = filename_starts, filename_times, filename_conduction
if !all(isfile.(filenames))
    @warn "incomplete root!"
end

##
# folder_data = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/activation"
# filename_times = joinpath(folder_data, "times.float32")
# filename_conduction = joinpath(folder_data, "conduction.float32")
# filename_starts = joinpath(folder_data, "indices_start.int32")

##

act_times = ActivationTimes(
    read_binary(filename_starts, Int32),
    read_binary(filename_times, Float32),
)

##

conduction = read_binary(filename_conduction, Float32)
conduction[act_times.stops] .= 1

conduction_percent_sum, conduction_percent_count =
    collect_counts_n_sums(conduction, act_times.starts, act_times.stops)

mask_nonzeros = .!iszero.(conduction_percent_count)

conduction_percent_mean = zeros(size(conduction_percent_sum))
conduction_percent_mean[mask_nonzeros] =
    conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

conduction_threshold = 0.95
indices_breaks = findall(conduction_percent_mean .< conduction_threshold)
# indices_breaks = convert.(Int32, indices_breaks)

##

hist(conduction_percent_mean, bins = 200, cumulative = true, density = true)

##

act_times_subset = create_act_times_subset(act_times, indices_breaks)
adj_matrix_breaks = adj_matrix[indices_breaks, indices_breaks]
cc = connected_components(SimpleGraph(adj_matrix_breaks))

##

act_graphs = ActivatedGraph[]
indices_breaks_connected = typeof(indices_breaks)[]

for component in cc

    if length(component) < 42
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

##

moving_breaks = find_moving_breaks(act_graphs, 20.0)

##

t_threshold = 1000.0
rotors = Rotor[]

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

    r = Rotor(lifetime_max, indices_points, Int[])
    @show lifetime_max

    push!(rotors, r)

end

##

result = Dict("components" => indices_breaks_connected, "rotors" => rotors)

write("./tmp/result.json", json(result))

##

t_live_maxima = (rotors.t_maxs - rotors.t_mins) .|> findmax .|> first
indices_rotors = findall(t_live_maxima .> t_threshold)

@info "$(length(indices_rotors)) rotors found"

result = Dict{String,Any}()
result["rotors"] = []

for i in indices_rotors
    t_mins = rotors.t_mins[i]
    t_maxs = rotors.t_maxs[i]
    t_live = t_maxs - t_mins
    t_live_max, i_t_live_max = findmax(t_live)
    # ids_t_live_max = rotors.ids[i][i_t_live_max]
    indices_rotor = indices_breaks_connected[i]

    result_dict = Dict("t_live" => t_live_max, "indices_rotor" => indices_rotor)

    push!(result["rotors"], deepcopy(result_dict))

end

result["components"] = indices_breaks_connected

##

using JSON

write("./tmp/result.json", json(result))

##













##

i_component = findmax(length.(indices_breaks_connected))[2]

times_component = times_breaks_connected[i_component]
starts_component = starts_breaks_connected[i_component]
stops_component = stops_breaks_connected[i_component]
adj_matrix_component = adj_matrix_breaks_connected[i_component]

is_available_component = ones(Bool, size(times_component))
# times_min_breaks = times[starts[indices_breaks]]

# for i in indices_breaks
#     is_available_component[starts[i]:stops[i]] .= true
# end


##

rotors = find_rotors(
    times = times_component,
    starts = starts_component,
    stops = stops_component,
    adj_matrix = adj_matrix_component,
    dt_max = 20.0f0,
    is_available = is_available_component,
)

##

using ProfileView
ProfileView.@profview rotor_ids, t_mins, t_maxs, indices_t_min = find_rotors(
    times = times_component,
    starts = starts_component,
    stops = stops_component,
    adj_matrix = adj_matrix_component,
    dt_max = 20.0f0,
    is_available = is_available_component,
)


##

using Profile

@profile for i = 1:3
    find_rotors(
        times = times_component,
        starts = starts_component,
        stops = stops_component,
        adj_matrix = adj_matrix_component,
        dt_max = 20.0f0,
        is_available = ones(Bool, size(times_component)),
    )
end

##

using BenchmarkTools

@benchmark find_rotors(
    times = times_component,
    starts = starts_component,
    stops = stops_component,
    adj_matrix = adj_matrix_component,
    dt_max = 20.0f0,
    is_available = ones(Bool, size(times_component)),
)

##

open("./tmp/profile.txt", "w") do s
    Profile.print(
        IOContext(s, :displaysize => (24, 500)),
        format = :flat,
        sortedby = :count,
    )
end


##
