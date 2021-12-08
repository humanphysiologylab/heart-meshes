function collect_counts_n_sums(
    a::Vector{F},
    starts::Vector{I},
    stops::Vector{I},
) where {F<:AbstractFloat} where {I<:Integer}

    n_points = length(starts)
    sums = zeros(n_points)
    counts = zeros(Int, n_points)

    @views for (i_point, (start, stop)) in enumerate(zip(starts, stops))
        r = start:stop
        a_slice = a[r]
        sums[i_point] += sum(a_slice)
        counts[i_point] += length(r)
    end

    return sums, counts

end
