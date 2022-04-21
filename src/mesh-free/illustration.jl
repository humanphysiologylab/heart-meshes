include("../io/load_adj_matrix.jl")
include("../io/load_arrays.jl")

include("../ActivatedGraphs/ActivatedGraphs.jl")
include("../ActArrays/ActArrays.jl")
include("../ActivatedMeshes/ActivatedMeshes.jl")

include("../cl/process_arrays.jl")

using Graphs
using StatsBase
using Base.Iterators, Base.Threads
using DataFrames, CSV

op_reduce(x) = takewhile(isfinite, x) |> mean

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

##

heart = 15
group = 3
stim = 37

folder_save = joinpath(
    "/Users/andrey/Work/HPL/data/algo-illustration/",
    "$heart-$group-$stim"
)
mkpath(folder_save)

folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix)
g = SimpleGraph(A)
a = load_arrays(heart, group, stim; folder_rheeda)

##

c_mean = reduce(a, :conduction, op_reduce)
indices_breaks = findall(c_mean .< 1.)
cc = connected_components(g[indices_breaks])
cc = sort(cc, by=length, rev=true)
cc = [indices_breaks[c] for c in cc]

##

folder_geometry_heart = joinpath(folder_rheeda, "geometry", "M$heart")

filename_points = joinpath(folder_geometry_heart, "points.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

##

component_length_min = 100
dt_max=50.
lifetime_min=1000.

rows = []
for (i, component) in enumerate(cc)
    length(component) < component_length_min && continue
    rows_component = process_component(component, a; dt_max, lifetime_min)
    isnothing(rows_component) && continue
    for row in rows_component
        row[:heart] = heart
        row[:group] = group
        row[:stim] = stim
        row[:component_id] = i
        row[:thread_id] = threadid()
    end
    append!(rows, rows_component)
end

df = DataFrame(rows)

##


using PlotlyJS

color = fill(NaN, length(a))

for (i, row) in enumerate(eachrow(df))
    c = cc[row.component_id]
    color[c] .= row.component_id
end

# for (i, c) in enumerate(cc) # [1:5])
#     color[c] .= i
# end

# color = zeros(Int, length(a))
# color[indices_breaks] .= 1

points_sparce = points[1: 100: end, :]
color_sparce = color[1: 100: end]

trace_components = scatter3d(;
    x = points_sparce[:, 1],
    y = points_sparce[:, 2],
    z = points_sparce[:, 3],
    marker_color = color_sparce,
    marker_size = 1,
    mode = "markers"
)

##

filename_elements = joinpath(folder_geometry_heart, "elements.int32")
elements = read_binary(filename_elements, Int32, (4, :))
elements = permutedims(elements, (2, 1))
elements .+= 1

filename_points = joinpath(folder_geometry_heart, "points.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

folder_adj_vertices = joinpath(folder_geometry_heart, "adj-vertices")
A_vertices = load_adj_matrix(folder_adj_vertices, false)

folder_adj_elements = joinpath(folder_geometry_heart, "adj-elements")
A_elements = load_adj_matrix(folder_adj_elements)

##

include("run_gradient_descent.jl")
include("load_mesh.jl")

folder_activation = joinpath(folder_rheeda, "activation-times")

##

point2element = [Int[] for i in 1:size(points, 1)]

for (i_element, element) in enumerate(eachrow(elements))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end

##

mesh = load_mesh(
    heart,
    group,
    stim;
    A_vertices,
    A_elements,
    elements,
    points,
    folder_activation
)

##

dfs_traj = []

folder_traj = joinpath(folder_save, "trajectories")
mkpath(folder_traj)

for (i_row, row) in enumerate(eachrow(df))

    i_element_start = point2element[row.v_start] |> first

    t_stop = row.t_start + 50.
    step = -100.
    traj = run_gradient_descent(mesh, i_element_start; step, t_stop)
    
    tag = string(row.component_id, pad=3) * "-" * string(i_row, pad=3)

    filename = joinpath(
        folder_traj,
        tag * ".csv"
    )
    CSV.write(filename, traj)
    
    push!(dfs_traj, traj)

end

##

# dfs_traj = []


# for (i_row, row) in enumerate(eachrow(df))

#     filename = joinpath(
#         folder_traj,
#         "M$(row.heart)-G$(row.group)-S$(row.stim)-$(row.component_id).csv"
#     )

#     # @assert isfile(filename)
#     traj = CSV.read(filename, DataFrame)
#     push!(dfs_traj, traj)
# end 

##

traces_traj = []

for traj in dfs_traj
    trace = scatter3d(;
        x = traj.x,
        y = traj.y,
        z = traj.z,
        mode = "lines",
        line_width = 3
    )
    push!(traces_traj, trace)
end

plot([trace_components, traces_traj...])


##

filename_indices_breaks = joinpath(folder_save, "indices_breaks.float64")
write(filename_indices_breaks, color)
