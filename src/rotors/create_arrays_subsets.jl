include("structs.jl")


function create_arrays_subsets(
    times::Vector{AbstractFloat},
    starts::Vector{Integer},
    indices_subset::Vector{Integer},
)

    n_times = length(times)
    n_subset = length(indices_subset)
    stops = create_stops(starts, n_times)

    starts_subset_native = starts[indices_subset]
    stops_subset_native = stops[indices_subset]

    lengths_subset = @. stops_subset_native - starts_subset_native + 1
    stops_subset = cumsum(lengths_subset)
    starts_subset = similar(stops_subset)
    starts_subset[2:end] = stops_subset[1:end-1] .+ 1
    starts_subset[1] = 1

    n_times_subset = sum(lengths_subset)
    times_subset = zeros(F, n_times_subset)

    @assert n_subset == length(stops_subset) == length(starts_subset)

    @inbounds @simd for i = 1:n_subset
        start = starts_subset_native[i]
        stop = stops_subset_native[i]
        start_subset = starts_subset[i]
        stop_subset = stops_subset[i]
        times_subset[start_subset:stop_subset] = times[start:stop]
    end

    return (; starts_subset, stops_subset, times_subset)

end


function create_act_times_subset(
    act_times::ActivationTimes,
    indices_subset::Vector{Int},
)::ActivationTimes

    starts = act_times.starts
    stops = act_times.stops
    times = act_times.times

    starts_subset_native = starts[indices_subset]
    stops_subset_native = stops[indices_subset]

    lengths_subset = @. stops_subset_native - starts_subset_native + 1
    stops_subset = cumsum(lengths_subset)
    starts_subset = similar(stops_subset)
    starts_subset[2:end] = stops_subset[1:end-1] .+ 1
    starts_subset[1] = 1

    times_subset = zeros(sum(lengths_subset))

    act_times_subset = ActivationTimes(starts_subset, times_subset, stops_subset)

    @inbounds @simd for i = 1:length(indices_subset)
        start = starts_subset_native[i]
        stop = stops_subset_native[i]
        start_subset = starts_subset[i]
        stop_subset = stops_subset[i]
        times_subset[start_subset:stop_subset] = times[start:stop]
    end

    return act_times_subset

end
