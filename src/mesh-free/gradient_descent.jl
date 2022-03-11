
dfs = []

##
index_tetrahedron = 142_000  # good
index_tetrahedron = 242_000


t = mesh.elements[index_tetrahedron, :]
t_coords = get_tetra_points(mesh, index_tetrahedron)
t_center = mean(t_coords, dims=1)[1, :]
t_times = find_nearest_times(mesh, t, 6000.)
t_start = mean(t_times)
cv = calculate_cv(t_coords, t_times)

##

function gradient_descent_step(time, p, index_tetrahedron, mesh; Δt=-1.)

    t = mesh.elements[index_tetrahedron, :]

    t_coords = get_tetra_points(mesh, index_tetrahedron)
    t_times = find_nearest_times(mesh, t, time)

    cv = calculate_cv(t_coords, t_times)

    time_next = time + Δt
    p_next = p + Δt * cv
    i_next = edge_hopping(index_tetrahedron, p_next, mesh)[1]

    if isnothing(i_next)
        i_next = rand(neighbors(mesh.graph_elements, index_tetrahedron))
        t_coords = get_tetra_points(mesh, i_next)
        p_next = mean(t_coords, dims=1)[1, :]
    end

    # n_facets = 4
    # success = false

    # for _ in 1: n_facets
    #     if !isnothing(i_next)
    #         success = true 
    #         continue
    #     end
    #     facet_indices = select_outer_facet(p_next, t_coords)
    #     facet = t_coords[facet_indices, :]
    #     n⃗ = calculate_facet_norm(facet)
    #     n⃗ /= norm(n⃗)
    #     cv_n⃗ = (cv ⋅ n⃗) * n⃗
    #     cv -= cv_n⃗

    #     time_next = time + Δt
    #     p_next = p + Δt * cv

    #     i_next = edge_hopping(index_tetrahedron, p_next, mesh)[1]

    # end

    # !success && return

    t_times = find_nearest_times(mesh, mesh.elements[i_next, :], time_next)
    t_coords = get_tetra_points(mesh, i_next)
    time_next = interpolate_baricentric(p_next, t_coords, t_times)

    return time_next, p_next, i_next

end

##

t_next, p_next = t_start, t_center
for _ in 1: 5
    @show t_next, p_next, i_next = gradient_descent_step(t_next, p_next, index_tetrahedron, mesh)
end
##

using DataStructures
cb_capacity = 200
cb = CircularBuffer{typeof(t_next)}(cb_capacity)

function terminate(cb, threshold = 1.)
    !isfull(cb) && return false
    n = cb.capacity
    head = mean(cb[1: n ÷ 2])
    tail = mean(cb[n ÷ 2: end])
    return head - tail < threshold
end

##
rows = []

t_next, p_next = t_start, t_center
i_next = index_tetrahedron

row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
push!(rows, row)

empty!(cb)

# for _ in 1: 1_000
while true
    t_next, p_next, i_next = gradient_descent_step(t_next, p_next, i_next, mesh, Δt=-1e-1)
    push!(cb, t_next)
    terminate(cb, 0.001) && break
    @show t_next
    row = (t = t_next, x = p_next[1], y = p_next[2], z = p_next[3], i = i_next)
    push!(rows, row)
end

@show length(rows)

##

df = DataFrame(rows)
# df = df[end-50:end, :]
df = df[1 : 1000, :]

##

push!(dfs, df)

##

surrounders = []
for i in df.i
    isnothing(i) && continue
    append!(surrounders, neighbors(mesh.graph_elements, i))
end
unique!(surrounders)
filter!(x -> x ∉ df.i, surrounders)

##
traces = []

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

stride = 100
trace_bg = scatter3d(;
    x=points[1: stride: end, 1],
    y=points[1: stride: end, 2],
    z=points[1: stride: end, 3],
    mode="markers",
    marker_size=1,
    marker_color="lightgrey"
    # colorscale="Greys",
    # marker_color=times_stop[1: stride: end]
)
push!(traces, trace_bg)

plot(
    [t for t in traces],
    # Layout(width=500, height=500, scene_aspectratio=attr(x=1, y=1, z=0.5)),
    # style=:simple_white
)


##



traces = []

for df in dfs
    trace = scatter3d(;
        x = df.x,
        y = df.y,
        z = df.z,
        mode = "lines",
        # marker_size = 2
        # line_color="grey",
        # showlegend=false
    )
    push!(traces, trace)
end

plot(
    [t for t in traces],
)