p = [
    71.81563e3,
    54.61138e3,
    83.67000e3
]

dist, v = eachrow(ag[:points][vs_extended, :] .- p') .|> norm |> findmin
v = vs_extended[v]

vs = neighborhood(ag.graph, v, 15_000.)

##

indices = df[t_min .< df.t .< t_max, :i] |> unique
vs_traj = mesh.elements[indices, :] |> unique

vs_rand = vs_traj[randperm(length(vs_traj))][1:1000]
vs_traj_extended = extend_area(ag.graph, vs_rand, 2_000.)

##

vs_sub = [vs..., vs_traj_extended...] |> unique
ag_sub = ActivatedGraphs.induced_subgraph(ag, vs_sub)

elements_sub = map(vs) do i
    point2element[i]
end
elements_sub = vcat(elements_sub...) |> unique

elements_sub_traj = map(vs_traj_extended) do i
    point2element[i]
end
elements_sub_traj = vcat(elements_sub_traj...) |> unique

elements_sub_rand = [
    elements_sub[randperm(length(elements_sub))][1:4000]...,
    # elements_sub_traj[randperm(length(elements_sub_traj))][1:1000]...
]

## 

time_target = 7500.

traces_cv = []

for i in elements_sub_rand

    t = mesh.elements[i, :]

    t_coords = get_tetra_points(mesh, i)
    t_times = find_nearest_times(mesh, t, time_target)
    p_next = mean(t_coords, dims=1)[1, :]

    cv = calculate_cv(t_coords, t_times)
    
    vector_draw = hcat(p_next, p_next + cv)

    trace = scatter3d(;
        x = vector_draw[1, :],
        y = vector_draw[2, :],
        z = vector_draw[3, :],
        mode = "lines",
        # marker_size = 2
        line_color="grey",
        # line_size=10,
        # lines_size=10,
        # marker_size=10
        showlegend=false
    )
    push!(traces_cv, trace)

end

points_draw = ag_sub[:points]
trace = scatter3d(;
    x=points_draw[1: stride: end, 1],
    y=points_draw[1: stride: end, 2],
    z=points_draw[1: stride: end, 3],
    mode="markers",
    marker_size=2,
    marker_color=times_last_cut[1: stride: end],
    opacity=0.1
    # marker_color=vs_extended[1: stride: end]
    # colorscale="Viridis"
)

traces = [
    traces_cv...,
    traces_traj...,
    trace
]

plot(traces)

# plot(trace)
