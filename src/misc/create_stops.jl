function create_stops(starts::Vector{T}, n_times::Integer)::Vector{T} where {T<:Integer}
    stops = similar(starts)
    stops[1:end-1] = starts[2:end] .- 1
    stops[end] = n_times
    return stops
end
