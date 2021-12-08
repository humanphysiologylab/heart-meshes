using ProgressMeter
using SparseArrays

##
include("read_binary.jl")


i_heart = 13
i_group = 2
i_stim = string(13, pad = 2)

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

times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)
n_times = length(conduction)

starts = read_binary(filename_starts, Int32)
stops = create_stops(starts, n_times)

##

include("calculate_average_conduction.jl")

conduction_percent_sum, conduction_percent_count =
    calculate_average_conduction(conduction, starts, stops)

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

adj_matrix = load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart")

##

# include("create_arrays_subsets.jl")

# starts_subset, stops_subset, times_subset = create_arrays_subsets(times, starts, indices_breaks)
# adj_matrix_subset = adj_matrix[indices_breaks, indices_breaks]
# rotor_ids, t_mins, t_maxs = find_rotors(times_subset, starts_subset, adj_matrix_subset)

##
include("find_rotors.jl")
include("visit_breaks.jl")

is_available = zeros(Bool, size(times))
# is_available[1] = true

times_min_breaks = zeros(length(indices_breaks))

for (ii, i) in enumerate(indices_breaks)
    is_available[starts[i]:stops[i]] .= true
    # println(i)
    @assert issorted(times[starts[i]:stops[i]-1])
    times_min_breaks[ii] = times[starts[i]]
end

rotor_ids, t_mins, t_maxs, indices_t_min = find_rotors(
    times = times,
    starts = starts,
    stops = stops,
    adj_matrix = adj_matrix,
    dt_max = 20.0f0,
    is_available = is_available,
)

indices_rotors = map(x -> searchsortedlast(starts, x), findall(x -> !iszero(x), rotor_ids))
indices_t_min_vertices = map(x -> searchsortedlast(starts, x), indices_t_min)

##
setdiff(indices_rotors, indices_breaks)
setdiff(indices_breaks, indices_rotors)

setdiff(indices_t_min_vertices, indices_breaks)

setdiff(indices_t_min_vertices, indices_rotors)
@show isdisjoint(indices_rotors, indices_t_min_vertices)



##
is_visited = zeros(Bool, size(is_available))

visit_breaks(
    i_point,
    times = times,
    is_available = is_available,
    is_visited = is_visited,
    starts = starts,
    stops = stops,
    adj_matrix = adj_matrix,
    dt_max = 30.0f0,
)
