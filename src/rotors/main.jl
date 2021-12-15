using ProgressMeter
using SparseArrays

include("../io/read_binary.jl")
include("../misc/create_stops.jl")
include("../io/load_adj_matrix.jl")

##
i_heart = 13
i_group = 2
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
folder_data = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/activation"
filename_times = joinpath(folder_data, "times.float32")
filename_conduction = joinpath(folder_data, "conduction.float32")
filename_starts = joinpath(folder_data, "indices_start.int32")

##

times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)
n_times = length(conduction)

starts = read_binary(filename_starts, Int32)
stops = create_stops(starts, n_times)

##

include("../conduction/collect_counts_n_sums.jl")

conduction_percent_sum, conduction_percent_count =
    collect_counts_n_sums(conduction, starts, stops)

mask_nonzeros = .!iszero.(conduction_percent_count)

conduction_percent_mean = zeros(size(conduction_percent_sum))
conduction_percent_mean =
    conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

##
hist(conduction_percent_mean, bins = 200, cumulative = true, density = true)

##

conduction_threshold = 0.95
indices_breaks = findall(conduction_percent_mean .< conduction_threshold)
indices_breaks = convert.(Int32, indices_breaks)

##

adj_matrix = load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix")

##

include("create_arrays_subsets.jl")

starts_breaks, stops_breaks, times_breaks =
    create_arrays_subsets(times, starts, indices_breaks)
adj_matrix_breaks = adj_matrix[indices_breaks, indices_breaks]

##
using Graphs
g = SimpleGraph(adj_matrix_breaks)
cc = connected_components(g)

hist(log10.(length.(cc)), bins = 100)

##

starts_breaks_connected = typeof(starts_breaks)[]
stops_breaks_connected = typeof(starts_breaks)[]
times_breaks_connected = typeof(times_breaks)[]
adj_matrix_breaks_connected = typeof(adj_matrix_breaks)[]
indices_breaks_connected = typeof(indices_breaks)[]

@showprogress for component in cc
    if length(component) < 10
        continue
    end
    indices = indices_breaks[component]
    arrays = create_arrays_subsets(times, starts, indices)
    push!(starts_breaks_connected, arrays.starts_subset)
    push!(stops_breaks_connected, arrays.stops_subset)
    push!(times_breaks_connected, arrays.times_subset)

    push!(adj_matrix_breaks_connected, adj_matrix[indices, indices])
    push!(indices_breaks_connected, indices)
end

##
include("find_rotors.jl")
include("visit_breaks.jl")

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

rotor_ids, t_mins, t_maxs, indices_t_min = find_rotors(
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
    times = times,
    starts = starts,
    stops = stops,
    adj_matrix = adj_matrix,
    dt_max = 20.0f0,
    is_available = is_available,
)
