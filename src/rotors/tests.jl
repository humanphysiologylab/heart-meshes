using Test
using SparseArrays
include("find_rotors.jl")

starts = [1, 3, 6, 9]
stops = [2, 5, 8, 10]
times = [0.0, 2.0, 0.1, 2.1, 3.0, 0.2, 1.1, 2.3, 1.0, 2.2]

rotor_ids_true = [1, 3, 1, 3, 4, 1, 2, 3, 2, 3]

is_available = collect(trues(size(times)))
is_visited = collect(falses(size(times)))

I = [1, 2, 3]
J = [2, 3, 4]
V = trues(size(I))
A = sparse(vcat(I, J), vcat(J, I), vcat(V, V))

dt_max = 0.21

index_t_min = 1

##

visit_breaks(
    index_t_min,
    times = times,
    is_available = is_available,
    is_visited = is_visited,
    starts = starts,
    stops = stops,
    adj_matrix = A,
    dt_max = dt_max,
)

@test is_available == (rotor_ids_true .≠ 1)
@test is_available == .!is_visited

##

is_visited = collect(falses(size(times)))

linear_range = 1:length(times)
index_t_min_available = findmin(times[is_available])[2]
index_t_min = linear_range[is_available][index_t_min_available]

visit_breaks(
    index_t_min,
    times = times,
    is_available = is_available,
    is_visited = is_visited,
    starts = starts,
    stops = stops,
    adj_matrix = A,
    dt_max = dt_max,
)

@test is_available ≠ is_visited
@test is_visited == (rotor_ids_true .== 2)#  .∈ Ref(fibrosis_ids)
@test is_available == (rotor_ids_true .∉ Ref([1, 2]))


##

is_available = collect(trues(size(times)))
is_visited = collect(falses(size(times)))

rotor_ids, t_mins, t_maxs, indices_t_min = find_rotors(
    times = times,
    starts = starts,
    stops = stops,
    adj_matrix = A,
    dt_max = dt_max,
    is_available = is_available,
)

@test rotor_ids == rotor_ids_true


##

include("./create_arrays_subsets.jl")

indices_subset = [1, 3]
arrays_subsets = create_arrays_subsets(times, starts, indices_subset)

@test arrays_subsets.starts_subset == [1, 3]
@test arrays_subsets.stops_subset == [2, 5]
@test arrays_subsets.times_subset == [0.0, 2.0, 0.2, 1.1, 2.3]
