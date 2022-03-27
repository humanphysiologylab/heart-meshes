using Statistics


function find_period(df::DataFrame, mesh::ActivatedMesh)

    t_min, t_max =  minimum(df.t), maximum(df.t)
    periods = []
    for i in unique(df.i)
        v = mesh.elements[i, :] |> first
        times = get_subarray(mesh, v, :times)
        mask = t_min .< times .< t_max
        times_masked = times[mask]
        append!(periods, diff(times_masked))
    end

    period = median(periods)

end
