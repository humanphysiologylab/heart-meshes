function find_nearest_times(mesh, indices_vertices, time)

    map(indices_vertices) do v
        times = ActivatedMeshes.get_vertex_vector(mesh, v, :times)
        i = findmin(abs.(times .- time))[2]
        times[i]
    end

end
