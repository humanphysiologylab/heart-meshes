using PlotlyJS

traces = []

trace = scatter3d(;
    x=t_coords[:, 1],
    y=t_coords[:, 2],
    z=t_coords[:, 3],
    mode="markers",
    # marker_size=1,
    # marker_color="grey"
    # colorscale="Greys",
    # marker_color=times_stop[1: stride: end]
)
push!(traces, trace)

t_center = mean(t_coords, dims=1)[1, :]

cv = [1, 1, 1]
p_line = hcat(t_center, t_center .+ cv)'

trace = scatter3d(;
    x=p_line[:, 1],
    y=p_line[:, 2],
    z=p_line[:, 3],
    mode="markers",
    # marker_size=1,
    # marker_color="grey"
    # colorscale="Greys",
    # marker_color=times_stop[1: stride: end]
)
push!(traces, trace)


indices, p, d = find_intersection(tetrahedron=t_coords, o_line=t_center, l_line=cv)

trace = scatter3d(;
    x=[p[1]],
    y=[p[2]],
    z=[p[3]],
    mode="markers",
    # marker_size=1,
    # marker_color="grey"
    # colorscale="Greys",
    # marker_color=times_stop[1: stride: end]
)
push!(traces, trace)

traces = [t for t in traces]

plot(traces)
