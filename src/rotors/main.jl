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
adj_matrix = convert(SparseMatrixCSC{Bool, Int}, adj_matrix)

##
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
# folder_data = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/activation"
# filename_times = joinpath(folder_data, "times.float32")
# filename_conduction = joinpath(folder_data, "conduction.float32")
# filename_starts = joinpath(folder_data, "indices_start.int32")

##

act_times = ActivationTimes(
    convert.(Int, read_binary(filename_starts, Int32)),
    convert.(Float64, read_binary(filename_times, Float32)),
)

##

conduction = convert.(Float64, read_binary(filename_conduction, Float32))
conduction[act_times.stops] .= 1

conduction_percent_sum, conduction_percent_count =
    collect_counts_n_sums(conduction, act_times.starts, act_times.stops)

mask_nonzeros = .!iszero.(conduction_percent_count)

conduction_percent_mean = zeros(size(conduction_percent_sum))
conduction_percent_mean[mask_nonzeros] =
    conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

conduction_threshold = 0.95
indices_breaks = findall(conduction_percent_mean .< conduction_threshold)

##

hist(conduction_percent_mean, bins = 200, cumulative = true, density = true)

##

act_times_subset = create_act_times_subset(act_times, indices_breaks)
adj_matrix_breaks = adj_matrix[indices_breaks, indices_breaks]
cc = connected_components(SimpleGraph(adj_matrix_breaks))

##

act_graphs = ActivatedGraph[]
indices_breaks_connected = typeof(indices_breaks)[]
component_size_min = 42

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

##

moving_breaks = find_moving_breaks(act_graphs, 20.0)

##

t_threshold = 1000.0
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
        "indices_points" => indices_points
    )
    @show i, lifetime_max, t_mins[id_lifetime_max]

    push!(rotors, r)

end

##

result = Dict("components" => indices_breaks_connected, "rotors" => rotors)

write("./tmp/result.json", json(result))

##




###

open("./tmp/profile.txt", "w") do s
    Profile.print(
        IOContext(s, :displaysize => (24, 500)),
        # format = :flat,
        # sortedby = :count,
    )
end


##
using ProfileView

ag = act_graphs[1]
is_available = ones(Bool, length(ag.times))
is_visited = zeros(Bool, length(ag.times))

# ProfileView.@profile \
n_visited = visit_breaks(
    1,
    act_graph = ag,
    is_available = is_available,
    is_visited = is_visited,
    dt_max = 20.,
)

##

is_available = ones(Bool, length(ag.times))
is_visited = zeros(Bool, length(ag.times))

ProfileView.@profview visit_breaks(1, act_graph = ag, is_available = is_available, is_visited = is_visited, dt_max = 20.)

##

report = []

@time for ag in act_graphs

    is_available = ones(Bool, length(ag.times))
    is_visited = zeros(Bool, length(ag.times))

    t = time()

    # n_visited = visit_breaks(
    #     1,
    #     act_graph = ag,
    #     is_available = is_available,
    #     is_visited = is_visited,
    #     dt_max = 20.,
    # )

    find_moving_breaks(ag, dt_max=20.)

    t = time() - t

    push!(
        report,
        Dict(
            "time" => t,
            "len_a" => size(ag.adj_matrix, 1),
            "len_t" => size(ag.times)
        )
    )
end
