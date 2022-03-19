function create_heart_trace(points; stride = 100)

    scatter3d(;
        x=points[1: stride: end, 1],
        y=points[1: stride: end, 2],
        z=points[1: stride: end, 3],
        mode="markers",
        marker_size=1,
        marker_color="lightgrey"
    )

end


function create_trajectories_traces(dfs::Vector{DataFrame})

    traces = []

    for df in dfs
        trace = scatter3d(;
            x = df.x,
            y = df.y,
            z = df.z,
            mode = "lines",
            # marker_size = 2

            # line_color="white",
            # line_size=10,
            # lines_size=10,
            # marker_size=10

            # showlegend=false
        )
        push!(traces, trace)
    end

    traces

end
