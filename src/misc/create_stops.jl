function create_stops(starts::Vector{T}, n_times::Integer)::Vector{T} where {T<:Integer}
    stops = similar(starts, T)
    stops[1:end-1] = starts[2:end] .- 1
    stops[end] = n_times
    return stops
end


function create_arrays_subsets(
    starts::Vector{T},
    indices_subset::Vector{T},
    arrays,
) where {T<:Integer}

    lengths = length.(arrays)
    len_array = first(lengths)

    @assert all(x -> x == len_array, lengths) "arrays have different lengths"

    n_subset = length(indices_subset)
    stops = create_stops(starts, len_array)

    starts_subset_native = starts[indices_subset]
    stops_subset_native = stops[indices_subset]

    lengths_subset = @. stops_subset_native - starts_subset_native + 1
    stops_subset = accumulate(+, convert.(T, lengths_subset))
    starts_subset = similar(stops_subset, T)

    starts_subset[2:end] = stops_subset[1:end-1] .+ 1
    starts_subset[1] = 1

    @assert n_subset == length(stops_subset) == length(starts_subset)

    len_array_subset = sum(lengths_subset)
    arrays_subset = map(a -> zeros(eltype(a), len_array_subset), arrays)

    @inbounds @simd for i = 1:n_subset
        start = starts_subset_native[i]
        stop = stops_subset_native[i]
        start_subset = starts_subset[i]
        stop_subset = stops_subset[i]

        for (a_subset, a) in zip(arrays_subset, arrays)
            a_subset[start_subset:stop_subset] = a[start:stop]
        end

    end

    return (; starts_subset, stops_subset, arrays_subset)

end
