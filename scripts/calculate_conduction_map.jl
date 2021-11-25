using SparseArrays
using ProgressMeter


function calculate_conduction_map_vec(
    adj_matrix::SparseMatrixCSC,
    times::Vector{F},
    starts::Vector{I},
    stride::Integer = 1,
    dt_max::AbstractFloat = 20.0;
    output_prealloc::Union{Vector{F},Nothing} = nothing,
) where {F<:AbstractFloat} where {I<:Integer}

    stops = starts[2:end] .- 1
    append!(stops, length(times))

    n_points = length(starts)

    rows = rowvals(adj_matrix)

    if isnothing(output_prealloc)
        conduction_percent = fill(NaN, size(times))
    else
        conduction_percent = output_prealloc
    end

    @fastmath @inbounds begin

        #  @showprogress for i = 1:stride:n_points
        for i = 1:stride:n_points

            start_i, stop_i = starts[i], stops[i]
            times_i = @view times[start_i:stop_i]

            for (index_time_i, time_i) in enumerate(times_i)

                indices_neighbours = @view rows[nzrange(adj_matrix, i)]
                n_neighbours = length(indices_neighbours)
                conduction_successes = 0

                for j in indices_neighbours

                    start_j, stop_j = starts[j], stops[j]
                    times_j = @view times[start_j:stop_j]

                    dts = times_j .- time_i
                    success = any(abs.(dts) .< dt_max)
                    conduction_successes += success

                end

                percent = conduction_successes / n_neighbours
                conduction_percent[start_i+index_time_i-1] = percent

            end

        end

    end

end


function calculate_conduction_map(
    adj_matrix::SparseMatrixCSC,
    times::Vector{F},
    starts::Vector{I};
    stride::Integer = 1,
    dt_max::AbstractFloat = 20.0,
    output_prealloc::Union{Vector{F},Nothing} = nothing,
)::Union{Vector{F},Nothing} where {F<:AbstractFloat} where {I<:Integer}

    stops = similar(starts)
    @views stops[1:end-1] = starts[2:end] .- 1
    stops[end] = length(times)

    n_points = length(starts)

    rows = rowvals(adj_matrix)

    if isnothing(output_prealloc)
        conduction_percent = fill(NaN, size(times))
    else
        conduction_percent = output_prealloc
    end

    @fastmath @inbounds begin

        #  @showprogress for i = 1:stride:n_points
        for i = 1:stride:n_points

            start_i, stop_i = starts[i], stops[i]
            times_i = @view times[start_i:stop_i]

            for (index_time_i, time_i) in enumerate(times_i)

                indices_neighbours = @view rows[nzrange(adj_matrix, i)]
                n_neighbours = length(indices_neighbours)
                conduction_successes = 0

                for j in indices_neighbours

                    start_j, stop_j = starts[j], stops[j]
                    times_j = @view times[start_j:stop_j]

                    for time_j in times_j

                        dt = time_i - time_j
                        if abs(dt) < dt_max
                            conduction_successes += 1
                            break
                        end

                    end

                end

                percent = conduction_successes / n_neighbours
                conduction_percent[start_i+index_time_i-1] = percent

            end

        end

    end

    if isnothing(output_prealloc)
        return conduction_percent
    else
        return nothing
    end

end
