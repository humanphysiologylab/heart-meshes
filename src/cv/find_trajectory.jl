include("connect_grads.jl")


function find_trajectory(
    index_times_start;
    g::ActivatedGraph,
    is_forward=false,
    ∇t_min=0.,
    ∇t_max=0.05
)

    i = index_times_start
    trajectory = eltype(g.starts)[]

    while true

        successor = find_successor(i; g, is_forward, ∇t_min, ∇t_max)

        j = successor[:i_t]

        if iszero(j)
            break
        end

        push!(trajectory, j)

        i = j

    end

    trajectory

end
