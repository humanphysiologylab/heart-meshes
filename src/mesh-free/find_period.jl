using Statistics


function find_period(df::DataFrame, a::ActArray, elements::Matrix)

    t_min, t_max =  minimum(df.t), maximum(df.t)
    periods = []
    for i in unique(df.i)
        v = elements[i, :] |> first
        times = get_subarray(a, v, :times)
        mask = t_min .< times .< t_max
        times_masked = times[mask]
        append!(periods, diff(times_masked))
    end

    period = median(periods)

end


find_period(df::DataFrame, mesh::ActivatedMesh) = find_period(df, mesh.arrays, mesh.elements)
