using SparseArrays
using ProgressMeter
using Graphs, SimpleWeightedGraphs
using Distances

include("../io/load_geom_data.jl")
include("../io/load_adj_matrix.jl")
include("../io/read_binary.jl")

include("../ActivatedMeshes/ActivatedMeshes.jl")
using .ActivatedMeshes

##

folder = "/Volumes/Samsung_T5/HPL/rheeda/data/2d-meshes/"

suffix = "100um"
group = 4

filename_points = joinpath(folder, "G$(group)_points_$(suffix).float")
points = read_binary(filename_points, Float64, (2, :))
points = permutedims(points, (2, 1))

filename_elements = joinpath(folder, "G$(group)_elements_$(suffix).int")
elements = read_binary(filename_elements, Int, (3, :))
elements = permutedims(elements, (2, 1))
elements .+= 1

filename_I_element = joinpath(folder, "G$(group)_I_element_$(suffix).int")
I_element = read_binary(filename_I_element, Int)
filename_J_element = joinpath(folder, "G$(group)_J_element_$(suffix).int")
J_element = read_binary(filename_J_element, Int)

##

A_element = sparse(I_element, J_element, trues(size(I_element)))

##

filename_edges = joinpath(folder, "G$(group)_edges_$(suffix).int")
IJ = read_binary(filename_edges, Int, (2, :))
IJ = permutedims(IJ, (2, 1))
IJ .+= 1

I = IJ[:, 1]
J = IJ[:, 2]

W_up = colwise(
    Euclidean(),
    transpose(points[I, :]),
    transpose(points[J, :])
)

g = SimpleWeightedGraph(
    I,
    J,
    W_up
    # fill(dh, size(edges, 1))
)

A = g.weights

##

filename_starts = joinpath(folder, "G$(group)_starts_$(suffix).int")
starts = read_binary(filename_starts, Int)

filename_times = joinpath(folder, "G$(group)_times_$(suffix).float")
times = read_binary(filename_times, Float64)  # .|> float

##

mesh = ActivatedMesh(
    A,
    A_element,
    elements,
    starts,
    Dict(:times => times),
    Dict(:points => points)
)

##

include("../mesh-free/calculate_cv.jl")
include("../mesh-free/intersections.jl")
include("../mesh-free/baricenter.jl")
include("../mesh-free/find_next_tetrahedron.jl")
include("../mesh-free/find_nearest_times.jl")
include("../mesh-free/plot_tetrahedron_edges.jl")

include("edge_hopping.jl")
include("gradient_descent_step.jl")

##

using DataStructures
using DataFrames, CSV


function terminate(cb, threshold = 1.)
    !isfull(cb) && return false
    n = capacity(cb)
    head = mean(cb[1: n ÷ 2])
    tail = mean(cb[n ÷ 2: end])
    return head - tail < threshold
end


function run_gradient_descent(
    i = nothing;
    t_start = 1e6,
    cb_capacity = 100,
    cb_threshold = 1e-3,
    step = -100
)

    i_element = isnothing(i) ? rand(1:nv(mesh.graph_elements)) : i

    t = mesh.elements[i_element, :]
    t_coords = get_tetra_points(mesh, i_element)
    t_center = mean(t_coords, dims=1)[1, :]
    t_times = find_nearest_times(mesh, t, t_start)
    t_start = mean(t_times)

    cb = CircularBuffer{typeof(t_start)}(cb_capacity)

    rows = []

    t_next, p_next = t_start, t_center
    i_next = i_element

    row = (t = t_next, x = p_next[1], y = p_next[2], i = i_next)
    push!(rows, row)

    while true
        t_next, p_next, i_next = gradient_descent_step(t_next, p_next, i_next, mesh; step)
        push!(cb, t_next)
        terminate(cb, cb_threshold) && break
        row = (t = t_next, x = p_next[1], y = p_next[2], i = i_next)
        push!(rows, row)
    end

    df = DataFrame(rows)

end

##

dfs = [run_gradient_descent(;step=-100) for _ in 1: 5];
df = dfs[end]

##

using PlotlyJS

##

traces = []

for df in dfs
    trace = scatter(;
        x = df.x,
        y = df.y,
        # z = df.z,
        mode = "lines+markers",
        markers_size=2,
        lines_width=1
    )
    push!(traces, trace)
end

##

plot([[t for t in traces]...])

##

filename_save_csv = joinpath(folder, "G$(group)_trajectory_$(suffix).csv")
CSV.write(filename_save_csv, dfs[end])
