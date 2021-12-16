using SparseArrays
using ProgressMeter

include("visit_breaks.jl")
include("structs.jl")


function find_moving_breaks(
    act_graph::ActivatedGraph;
    dt_max::AbstractFloat,
    is_available::Union{Vector{Bool},Nothing} = nothing,
)

    n_points = length(act_graph.starts)
    n_times = length(act_graph.times)

    ids = zeros(Int, n_times)
    is_visited = zeros(Bool, n_times)

    t_mins = Float64[]
    t_maxs = Float64[]

    linear_range = 1:n_times

    if isnothing(is_available)
        is_available = ones(Bool, size(act_graph.times))
    end

    rotor_id = 0
    n_visited = 0

    while any(is_available)

        rotor_id += 1

        t_min, index_t_min_available = findmin(act_graph.times[is_available])
        index_t_min = linear_range[is_available][index_t_min_available]

        n_visited = visit_breaks(
            index_t_min,
            act_graph = act_graph,
            is_available = is_available,
            is_visited = is_visited,
            dt_max = dt_max,
        )

        t_max = findmax(act_graph.times[is_visited])[1]
        push!(t_mins, t_min)
        push!(t_maxs, t_max)

        ids[is_visited] .= rotor_id
        is_available[is_visited] .= false
        is_visited[is_visited] .= false

    end

    return (; ids, t_mins, t_maxs)

end


function find_moving_breaks(act_graphs::Vector{ActivatedGraph}, dt_max::AbstractFloat)

    result = []

    @showprogress for ag in act_graphs
        rotors = find_moving_breaks(ag, dt_max = dt_max)
        push!(result, rotors)
    end

    return result

end
