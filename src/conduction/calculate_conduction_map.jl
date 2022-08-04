using SparseArrays

include("../misc/create_stops.jl")


function calculate_conduction_map(
    adj_matrix::SparseMatrixCSC,
    times::Vector{F},
    starts::Vector{I};
    cv_min::AbstractFloat = 10.0,  # um/s : 10 um/ms = 10 mm/s = 1 cm/s
    t_margin::AbstractFloat = 100.,  # ms
    output_prealloc::Union{Vector{F},Nothing} = nothing,
)::Union{Vector{F},Nothing} where {F<:AbstractFloat} where {I<:Integer}

    stops = create_stops(starts, length(times))

    n_points = length(starts)

    rows = rowvals(adj_matrix)
    vals = nonzeros(adj_matrix)

    if isnothing(output_prealloc)
        conduction_percent = fill(NaN, size(times))
    else
        conduction_percent = output_prealloc
    end

    ∇t_max = 1 / cv_min
    t_max = maximum(times) - t_margin

    @fastmath @inbounds begin

        for i in 1 : n_points

            start_i, stop_i = starts[i], stops[i]
            times_i = @view times[start_i:stop_i]
            nz_i = nzrange(adj_matrix, i)
            n_neighbours = length(nz_i)
            indices_neighbours = @view rows[nz_i]
            distanses_neighbours = @view vals[nz_i]

            for (index_time_i, time_i) in enumerate(times_i)

                time_i > t_max && continue

                conduction_successes = 0

                for (j, dist) in zip(indices_neighbours, distanses_neighbours)

                    start_j, stop_j = starts[j], stops[j]
                    times_j = @view times[start_j:stop_j]

                    for time_j in times_j

                        dt = time_i - time_j
                        ∇t  = dt / dist
                        if abs(∇t) < ∇t_max
                            conduction_successes += 1
                            break
                        end

                    end

                end

                percent = conduction_successes / n_neighbours
                conduction_percent[start_i+index_time_i-1] = percent

            end

        end

    end  # @fastmath @inbounds 

    if isnothing(output_prealloc)
        return conduction_percent
    else
        return nothing
    end

end
