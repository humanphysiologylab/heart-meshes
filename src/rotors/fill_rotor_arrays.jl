include("visit_breaks.jl")

function fill_rotor_arrays!(ag::ActivatedGraph, dt_max=20.)

    mask_breaks = ag[:conduction] .< 1

    ag[:parents] = zeros(ag.type_array, ag.len_array)
    ag[:roots] = deepcopy(ag[:parents])
    ag[:lifetime] = zeros(ag.len_array)
    ag[:dists] = fill(typemax(eltype(ag.graph.weights)), ag.len_array)
    ag[:is_leaf] = trues(ag.len_array)

    summary_info = []

    while true

        mask_discovered = ag[:parents] .== 0
        mask_available = mask_breaks .& mask_discovered .& ag[:is_available]

        !any(mask_available) && break

        indices = findall(mask_available)

        t_min, i_t_min = findmin(ag[:times][indices])
        i_t_min = convert(ag.type_array, indices[i_t_min])

        summary_info_item = visit_breaks!(i_t_min, g = ag, dt_max = dt_max)
        push!(summary_info, summary_info_item)

        # (n_visited > 10) && println(n_visited)

    end

    return summary_info

end
