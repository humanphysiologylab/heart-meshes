include("plot_tetrahedron_edges.jl")

##

df_slice = df[end-100: end, :]
t_slice = df_slice.t |> mean

##

surrounders = []
for i in df_slice.i
    isnothing(i) && continue
    append!(surrounders, neighbors(mesh.graph_elements, i))
end
unique!(surrounders)
filter!(x -> x ∉ df.i, surrounders)

##

traces_surrounders = []

for j in surrounders
    t_coords = get_tetra_points(mesh, j)
    t_coords_plot = plot_tetrahedron_edges(t_coords)
    trace = scatter3d(;
        x=t_coords_plot[:, 1],
        y=t_coords_plot[:, 2],
        z=t_coords_plot[:, 3],
        mode="lines",
        line_color="lightgrey",
        line_dash="dot",
        # marker_color="grey",
        showlegend=false
    )
    push!(traces_surrounders, trace)
end

##

traces_tetrahedrons = []
traces_cv = []

for i in unique(df_slice.i)

    if isnothing(i)
        continue
    end

    color = colors.tab10[1 + i % 10]

    t_coords = get_tetra_points(mesh, i)
    center =  mean(t_coords, dims=1)[1, :] .+ 10.
    t_times = find_nearest_times(mesh, mesh.elements[i, :], t_slice)

    cv = calculate_cv(t_coords, t_times)
    cv_normalized = cv / norm(cv)

    vector_draw = hcat(center, center + cv)

    t_coords_plot = plot_tetrahedron_edges(t_coords)
    trace = scatter3d(;
        x=t_coords_plot[:, 1],
        y=t_coords_plot[:, 2],
        z=t_coords_plot[:, 3],
        mode="lines",
        line_color=color,
        # marker_color="grey",
        showlegend=false
    )
    push!(traces_tetrahedrons, trace)

    trace = scatter3d(;
        x = vector_draw[1, :],
        y = vector_draw[2, :],
        z = vector_draw[3, :],
        mode = "lines",
        line_color=color,
        line_dash="dot",
        showlegend=false
    )
    push!(traces_cv, trace)

end

##

traces_traj = []

for (i_row, row) in enumerate(eachrow(df_slice))

    if isnothing(row.i)
        continue
    end

    color = colors.tab10[1 + row.i % 10]
    trace = scatter3d(;
        x = [row.x],
        y = [row.y],
        z = [row.z],
        mode = "markers",
        marker_size = 3,
        marker_color = color,
        showlegend=false
    )
    push!(traces_traj, trace)

end

##

trace_traj_line = scatter3d(;
    x = df_slice.x,
    y = df_slice.y,
    z = df_slice.z,
    mode = "lines",
    line_dash="dot",
    line_width=1,
    line_color="black",
    showlegend=false
)

##

plot([
    traces_traj...,
    traces_surrounders...,
    traces_tetrahedrons...,
    traces_cv...,
    trace_traj_line
    # trace_scatter,
    # trace_bg
])

##
