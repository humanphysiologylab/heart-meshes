surrounders = []
for i in df.i
    isnothing(i) && continue
    append!(surrounders, neighbors(mesh.graph_elements, i))
end
unique!(surrounders)
filter!(x -> x ∉ df.i, surrounders)

##

trace = scatter3d(;
    x = df[1:2, :x],
    y = df[1:2, :y],
    z = df[1:2, :z],
    mode = "markers",
    marker_size = 5,
    line_color="red",
    showlegend=false
)
push!(traces, trace)

trace = scatter3d(;
    x = df.x,
    y = df.y,
    z = df.z,
    mode = "lines",
    # marker_size = 2
    line_color="grey",
    showlegend=false
)
push!(traces, trace)


##

for i in unique(df.i)

    if isnothing(i)
        continue
    end

    color = colors.tab10[1 + i % 10]

    t_coords = get_tetra_points(mesh, i)
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
    push!(traces, trace)

end

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
    push!(traces, trace)
end

for (i_row, row) in enumerate(eachrow(df))

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
    push!(traces, trace)

end

##
