function create_arrays_subsets(
    times::Vector{F},
    starts::Vector{U},
    indices_subset::Vector{U},
) where {F<:AbstractFloat} where {U<:Integer}

    n_subset = length(indices_subset)

    n_times = length(times)
    stops = create_stops(starts, n_times)

    starts_subset_native = starts[indices_subset]
    stops_subset_native = stops[indices_subset]

    starts_subset = zeros(U, n_subset)
    stops_subset = zeros(U, n_subset)

    starts_subset[1] = 1
    stops_subset[1] = stops_subset_native[1] - starts_subset_native[1] + 1

    n_times_subset = sum(stops_subset_native .- starts_subset_native) + 1
    times_subset = zeros(F, n_times_subset)

    start_cumulative = 1

    for (i, (start, stop)) in enumerate(zip(starts_subset_native, stops_subset_native))

        r_native = start:stop

        start_subset = start_cumulative
        stop_subset = start_cumulative + (stop - start)
        r_subset = start_subset:stop_subset

        starts_subset[i] = start_subset
        stops_subset[i] = stop_subset

        times_subset[r_subset] = times[r_native]

        start_cumulative = stop_subset

    end

    return starts_subset, stops_subset, times_subset

end
