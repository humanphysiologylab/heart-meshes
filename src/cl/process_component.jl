function process_component(
    component,
    a::ActArray;
    dt_max = 50.,
    lifetime_min = 1000.
)

    times_subarrays = [get_subarray(a, i, :times) for i in component]
    times_sorted = (sort ∘ collect ∘ Iterators.flatten)(times_subarrays)
    dtimes = diff(times_sorted)
    mask_dt_max = dtimes .> dt_max

    indices_split = findall(mask_dt_max)
    indices_split_start = [1, (indices_split .+ 1)...]
    indices_split_end = [indices_split..., length(times_sorted)]

    rows = []

    for (i_start, i_end) in zip(indices_split_start, indices_split_end)
        
        t_start = times_sorted[i_start]
        t_end = times_sorted[i_end]
        lifetime = t_end - t_start
        lifetime < lifetime_min && continue

        v_start = findfirst(
            t -> any(t .== t_start),
            times_subarrays
        )
        v_end = findfirst(
            t -> any(t .== t_end),
            times_subarrays
        )

        periods = eltype(times_sorted)[]
        for times_subarray in times_subarrays
            mask = t_start .< times_subarray .< t_end
            τ = times_subarray[mask]
            append!(periods, diff(τ))
        end
        isempty(periods) && continue
        period = mode(periods)

        row = Dict(
            :t_start => t_start,
            :t_end => t_end,
            :lifetime => lifetime,
            :v_start => v_start,
            :v_end => v_end,
            :periods_mode => period,
            :component_size => length(component)
        )

        push!(rows, row)

    end

    rows

end
