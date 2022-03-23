include("../misc/create_stops.jl")


function compress_activation_times(
    vertices::Vector{Int32},
    times::Vector{Float32},
    n_points::Int32
)

    indices_sortperm = sortperm(vertices)
    vertices_sorted = vertices[indices_sortperm]
    times_sorted = times[indices_sortperm]

    n_points_found = last(vertices_sorted)

    if n_points > n_points_found
        @info "n_points > n_points_found\n$n_points > $n_points_found"
    elseif n_points < n_points_found
        @warn "n_points < n_points_found\n$n_points < $n_points_found"
    end

    starts = map(i -> searchsortedfirst(vertices_sorted, i), 1:n_points)
    stops = create_stops(starts, length(times))

    for (start, stop) ∈ zip(starts, stops)
        times_sorted[start:stop] .= sort(times_sorted[start:stop])
    end

    return starts, times_sorted, n_points_found

end
