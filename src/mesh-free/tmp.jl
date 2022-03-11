using DataFrames, CSV
using PlotlyJS
using Graphs, SimpleWeightedGraphs
using ProgressMeter
using UnPack

include("calculate_cv.jl")
include("intersections.jl")
include("baricenter.jl")
include("find_next_tetrahedron.jl")
include("find_nearest_times.jl")
include("plot_tetrahedron_edges.jl")

##

path_harddrive = "/Volumes/Samsung_T5"
path_harddrive = "/media/andrey/Samsung_T5"

filename_times = joinpath(
    path_harddrive,
    "Rheeda/activation/data-light/M13/G1/S13/times.float32"
)
times = read_binary(filename_times, Float32)

filename_starts = joinpath(
    path_harddrive,
    "Rheeda/activation/data-light/M13/G1/S13/indices_start.int32"
)
starts = read_binary(filename_starts, Int32)

A_vertices = load_adj_matrix(joinpath(folder, "adj_matrix"), false)

mesh = ActivatedMesh(A_vertices, A_tetra, tetra, starts, Dict(:times => times), Dict(:points => points))

##
rows = []

index_tetrahedron = 7_000

t = mesh.elements[index_tetrahedron, :]
t_coords = get_tetra_points(mesh, index_tetrahedron)
t_center = mean(t_coords, dims=1)[1, :]
t_times = find_nearest_times(mesh, t, 2000.)
t_start = mean(t_times)
cv = calculate_cv(t_coords, t_times)

row = (next=index_tetrahedron, p_next=t_center, t_next=t_start, plane_indices=[0, 0, 0], cv=cv)
push!(rows, row)

row = find_next_tetrahedron_v2(mesh, index_tetrahedron, t_center, t_start)
push!(rows, row)

##

# row = find_next_tetrahedron(mesh, index_tetrahedron, t_center, t_start)

##

@showprogress for j in 1: 1000

    row = find_next_tetrahedron_v2(
        mesh,
        row.next,
        row.p_next,
        row.t_next;
    )

    # row = Dict(:p => p_next, :i => next, :t => t_next, :cv => cv)

    if isnothing(row)
        @warn "exit"
        break
    end

    push!(rows, row)

end

##

df = DataFrame(rows)

##

traces = []

for (i_row, row) in enumerate(eachrow(df))

    color = colors.tab10[1 + i_row % 10]

    if isnothing(row.next)
        continue
    end

    p = row.p_next
    cv = row.cv

    trace = scatter3d(;
        x=[p[1], p[1] - cv[1]],
        y=[p[2], p[2] - cv[2]],
        z=[p[3], p[3] - cv[3]],
        mode="lines",
        line_color=color,
        line_dash="dash",
        showlegend=false
    )
    push!(traces, trace)

    t_coords = get_tetra_points(mesh, row.next)
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

    trace = scatter3d(;
        x=[row.p_next[1]],
        y=[row.p_next[2]],
        z=[row.p_next[3]],
        marker_color=color,
        marker_size=2
    )
    push!(traces, trace)

end

trajectory = transpose(hcat(df.p_next...))

trace = scatter3d(;
    x=trajectory[:, 1],
    y=trajectory[:, 2],
    z=trajectory[:, 3],
    mode="lines",
    lines_width=3,
    # marker_size=2,
    line_color="grey",
    showlegend=false
)
push!(traces, trace)

traces = [t for t in traces]

plot(traces)
