# function find_rotors(
#     times::Vector{F},
#     starts::Vector{U},
#     adj_matrix::SparseMatrixCSC,
#     dt_max::F
# ) where F <: AbstractFloat where U <: Integer

#     n_points = convert(U, length(starts))
#     n_times = convert(U, length(times))

#     stops = create_stops(starts, n_times)
#     rotor_ids = zeros(U, n_times)
#     is_available = ones(Bool, n_times)
#     is_visited = zeros(Bool, n_times)
#     t_mins = F[]
#     t_maxs = F[]
#     indices_t_min = U[]
#     linear_range = UnitRange(one(U), n_times)

#     rotor_id::U = 0

#     while any(is_available)

#         rotor_id += 1

#         t_min, index_t_min_rotor = findmin(times[is_available])
#         index_t_min = linear_range[is_available][index_t_min_rotor]

#         visit_breaks(
#             index_t_min,
#             times=times,
#             is_available=is_available,
#             is_visited=is_visited,
#             starts=starts,
#             stops=stops,
#             adj_matrix=adj_matrix,
#             dt_max=dt_max
#         )

#         t_max = findmax(times[is_visited])[1]
#         push!(t_mins, t_min)
#         push!(t_maxs, t_max)

#         push!(indices_t_min, index_t_min)

#         rotor_ids[is_visited] .= rotor_id
#         is_available[is_visited] .= false
#         is_visited[is_visited] .= false

#         @show sum(is_available), t_min, t_max

#         if rotor_id == 10
#             break
#         end

#     end

#     return rotor_ids, t_mins, t_maxs, indices_t_min

# end


function find_rotors(;
    times::Vector{F},
    starts::Vector{U},
    stops::Vector{U},
    adj_matrix::SparseMatrixCSC,
    dt_max::F,
    is_available::Vector{Bool},
) where {F<:AbstractFloat} where {U<:Integer}

    n_points = convert(U, length(starts))
    n_times = convert(U, length(times))

    rotor_ids = zeros(U, n_times)
    is_visited = zeros(Bool, n_times)
    t_mins = F[]
    t_maxs = F[]
    indices_t_min = U[]
    linear_range = UnitRange(one(U), n_times)

    rotor_id::U = 0

    while any(is_available)

        rotor_id += 1

        t_min, index_t_min_rotor = findmin(times[is_available])
        index_t_min = linear_range[is_available][index_t_min_rotor]

        visit_breaks(
            index_t_min,
            times = times,
            is_available = is_available,
            is_visited = is_visited,
            starts = starts,
            stops = stops,
            adj_matrix = adj_matrix,
            dt_max = dt_max,
        )

        t_max = findmax(times[is_visited])[1]
        push!(t_mins, t_min)
        push!(t_maxs, t_max)
        push!(indices_t_min, index_t_min)

        rotor_ids[is_visited] .= rotor_id
        is_available[is_visited] .= false
        is_visited[is_visited] .= false

        @show sum(is_available), t_min, t_max

        if rotor_id == 10
            break
        end

    end

    return rotor_ids, t_mins, t_maxs, indices_t_min

end
