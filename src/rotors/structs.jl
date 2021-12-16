using SparseArrays

include("../misc/create_stops.jl")


struct ActivationTimes{U<:Integer,F<:AbstractFloat}
    starts::Vector{U}
    times::Vector{F}
    stops::Vector{U}

    function ActivationTimes(
        starts::Vector{U},
        times::Vector{F},
    ) where {U<:Integer} where {F<:AbstractFloat}
        n_times = length(times)
        stops = create_stops(starts, n_times)
        new{U,F}(starts, times, stops)
    end

    function ActivationTimes(
        starts::Vector{U},
        times::Vector{F},
        stops::Vector{U},
    ) where {U<:Integer} where {F<:AbstractFloat}
        n_times = length(times)
        stops_check = create_stops(starts, n_times)
        if stops ≠ stops_check
            error("invalid stops")
        end
        new{U,F}(starts, times, stops)
    end

end


struct ActivatedGraph{U<:Integer,F<:AbstractFloat}
    starts::Vector{Int}
    stops::Vector{Int}
    times::Vector{F}
    adj_matrix::SparseMatrixCSC
    function ActivatedGraph(
        act_times::ActivationTimes{U,F},
        adj_matrix::SparseMatrixCSC,
    ) where {U<:Integer} where {F<:AbstractFloat}
        if !(length(act_times.starts) == size(adj_matrix, 1) == size(adj_matrix, 2))
            error("invalid adj_matrix size")
        end
        new{U,F}(act_times.starts, act_times.stops, act_times.times, adj_matrix)
    end
end


struct Rotor{U<:Integer}
    lifetime::AbstractFloat
    indices_points::Vector{U}
    indices_times::Vector{U}
end
