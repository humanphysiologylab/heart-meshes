filename_meta = "/Volumes/samsung-T5/HPL/Rheeda/rotors/cc-4d/13-3-37.csv"
df_cc = CSV.read(filename_meta, DataFrame)

##

dfs = DataFrame[]

# @showprogress for row in eachrow(df_cc[df_cc.lifetime .> 200, :])
@showprogress for row in eachrow(df_cc[1:10, :])

    i_time = row.i_max

    bfs_result = bfs(i_time, mesh)[1]
    i_start = bfs_result.i

    v = get_major_index(a, i_start)
    i = point2element[v] |> first

    time_start = row.t_max
    # time_stop = row.t_min + 10.

    df, metainfo = run_gradient_descent(mesh, i, step=-100, strategy=:random; time_start)
    push!(dfs, df)

    # push!(indices_start, i)
end

##

for (i, df) in enumerate(dfs)

    filename_save = joinpath(folder_save, "trajectories-4d", "$i.csv")
    CSV.write(filename_save, df)

end

##

dfs = [run_gradient_descent(mesh, i, step=-100, strategy=:random) for i in indices_start];


##

##

# dfs = [run_gradient_descent(mesh, step=-100, strategy=:random) for _ in 1: 10];

# dfs = [run_gradient_descent(mesh, 1, step=-100, strategy=:closest)];
dfs = [run_gradient_descent(mesh, i, step=-100, strategy=:random)];

df = dfs[end]

##

traces = create_trajectories_traces(dfs)
trace_bg = create_heart_trace(mesh[:points])

##

plot([traces..., trace_bg])

##

traces_traj = []

for df in dfs

    cx = :x
    cy = :y
    cz = :z

    t = scatter3d(;
        x = df[:, cx],
        y = df[:, cy],
        z = df[:, cz],
        mode = "lines",
        # line_color = "grey"
    )

    push!(traces_traj, t)

end

plot([traces_traj...])

##

trace_scatter = scatter3d(;
    x = df.x,
    y = df.y,
    z = df.z,
    mode = "lines+markers",
    # marker_size = 2

    # line_color="white",
    line_size=0.5,
    # lines_size=10,
    marker_size=2

    # showlegend=false
)

plot([
    # traces...,
    trace_scatter,
    # trace_bg
])


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
