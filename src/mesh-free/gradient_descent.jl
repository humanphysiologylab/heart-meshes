dfs = [run_gradient_descent(mesh) for _ in 1: 1];
df = dfs[end]

##

traces = create_trajectories_traces(dfs)
trace_bg = create_heart_trace(mesh[:points])

##

plot([[t for t in traces]..., trace_bg])

##

t_min = 2600.
t_max = 7300.

indices = df[t_min .< df.t .< t_max, :i] |> unique
vs = mesh.elements[indices, :] |> unique

##

point2element = [Int[] for i in 1:size(mesh[:points], 1)]

@showprogress for (i_element, element) in enumerate(eachrow(mesh.elements))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end

##

ag = ActivatedGraph(
    mesh.graph_vertices.weights,
    mesh.starts,
    Dict(:times => mesh.vertex_vectors[:times]),
    Dict(:points => mesh.vertex_scalars[:points])    
)

vs_rand = vs[randperm(length(vs))][1:100]
vs_extended = extend_area(ag.graph, vs_rand, 2_000.)

ag_sub = ActivatedGraphs.induced_subgraph(ag, vs_extended)

##

elements_sub = map(vs_extended) do i
    point2element[i]
end

elements_sub = vcat(elements_sub...) |> unique

elements_sub_rand = elements_sub[randperm(length(elements_sub))][1:10]

##

dfs = [run_gradient_descent(mesh, i; t_start=5000.) for i in elements_sub_rand];

##

function last_masked(t, t_min, t_max)
    mask = t_min .< t .< t_max
    t_masked = t[mask]
    if isempty(t_masked)
        return -1.
    else
        return last(t_masked)
    end
end

##

times_last = reduce(ag_sub, :times, t -> last_masked(t, t_min, t_max))

t1 = quantile(times_last[times_last .≠ -1], 0.01)
t2 = t_max #  quantile(times_last, 0.99)
mask = t1 .< times_last .< t2
times_last[.!mask] .= NaN

##

n = 16

times_last_cut = map(times_last) do t
    searchsortedfirst(t1: (t2 - t1) / n : t2, t) |> float
end

times_last_cut[.!mask] .= NaN

##

stride = 1
points_draw = ag_sub[:points]

traces = []

trace = scatter3d(;
    x=points_draw[1: stride: end, 1],
    y=points_draw[1: stride: end, 2],
    z=points_draw[1: stride: end, 3],
    mode="markers",
    marker_size=2,
    marker_color=times_last_cut[1: stride: end],
    # marker_color=vs_extended[1: stride: end]
    # colorscale="Viridis"
)
push!(traces, trace)

traces_traj = create_trajectories_traces(dfs[1:5])
append!(traces, traces_traj)


plot([t for t in traces])


##

i = elements_sub_rand[2]
p = [
    71.81563e3,
    54.61138e3,
    83.67000e3
]
i, trace = edge_hopping(i, p, mesh; save_trace=true)

p_last = get_tetra_points(mesh, trace[end])

# trace = scatter3d(;
#     x=p_last[:, 1],
#     y=p_last[:, 2],
#     z=p_last[:, 3],
#     mode="markers",
#     marker_size=4
#     # colorscale="Viridis"
# )
# push!(traces, trace)
