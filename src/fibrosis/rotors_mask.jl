using Graphs, SimpleWeightedGraphs
using ProgressMeter
using StatsBase
using DataFrames, CSV
using NearestNeighbors

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

include("../ActArrays/ActArrays.jl")

##

heart = 15

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"
folder_geometry = joinpath(folder_rheeda, "geometry", "M$heart")

folder_adj_matrix = joinpath(folder_geometry, "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)
g = SimpleWeightedGraph(A)

##

filename_points = joinpath(folder_geometry, "points.float32")
points = read_binary(filename_points, Float32, (3, :))
# points = permutedims(points, (2, 1))

##

folder_v2e = joinpath(folder_geometry, "v2e")
filename_v2e_starts = joinpath(folder_v2e, "starts.int32")
filename_v2e_indices_elements = joinpath(folder_v2e, "indices_elements.int32")

starts = read_binary(filename_v2e_starts, Int32)
indices_elements = read_binary(filename_v2e_indices_elements, Int32)

idx_mapper = ActArray(starts, Dict(:el => indices_elements))

function get_el(idx_mapper, i)
    get_subarray(idx_mapper, i, :el)
end

##

filename_elements = joinpath(folder_geometry, "elements.int32")
elements = read_binary(filename_elements, Int32, (4, :))
elements .+= 1
elements = permutedims(elements, (2, 1))

##

filename_meta = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet.csv"
folder_trajectories = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet"

df_meta = CSV.read(filename_meta, DataFrame)

##

tree = kdtree = KDTree(points)
nn(tree, points[:, :])

##

# ρs = 10 .^ (1: 0.1: 5)
ρ = 1e5
threshold = 5000  # um

masks = Dict()
for group in 1:4
    mask_vertices = falses(size(points, 2))
    mask_elements = falses(size(elements, 1))
    masks[group] = Dict(
        :vertices => mask_vertices,
        :elements => mask_elements
    )
end

# Threads.@threads for row_meta in eachrow(df_meta[df_meta.heart .== heart, :])
for row_meta in eachrow(df_meta[df_meta.heart .== heart, :])

    t_id = Threads.threadid()
    
    group = row_meta.group
    stim = row_meta.stim
    i = row_meta.i

    @show t_id, heart, group, stim, i

    filename_traj = joinpath(
        folder_trajectories,
        string(heart),
        string(group),
        string(stim, pad=2),
        string(i, pad=3) * ".csv"
    )

    traj = CSV.read(filename_traj, DataFrame)

    X = traj[:, [:x, :y, :z]] |> Matrix |> transpose
    nn_indices = nn(tree, X) |> first

    ds = dijkstra_shortest_paths(g, nn_indices)
    dists = ds.dists

    mask_rotor_environment = ds.dists .< threshold
    indices_out = findall(.!mask_rotor_environment)

    g_mask = g[indices_out]

    cc = connected_components(g_mask)
    length_max = maximum(length.(cc))

    for (i, c) in enumerate(cc)
        length(c) == length_max && continue
        mask_rotor_environment[indices_out[c]] .= true
    end

    # heart_id = heart == 13 ? 1 : 2
    heart_id = heart

    mask_dist = dists .< ρ
    mask_dist .&= mask_rotor_environment

    masks[group][:vertices] .|= mask_dist

    indices_dist = findall(mask_dist)
    indices_els = [get_el(idx_mapper, i) for i in indices_dist] |> Iterators.flatten |> unique

    masks[group][:elements][indices_els] .= true

end

##

folder_save = "/Volumes/samsung-T5/HPL/Rheeda/mask_rotors"

for group in 1: 4

    filename_save = joinpath(
        folder_save,
        "$(heart)-$(group)-vertices.bool"
    )

    open(filename_save, "w") do f
        x = collect(masks[group][:vertices])
        write(f, x)
    end

    filename_save = joinpath(
        folder_save,
        "$(heart)-$(group)-elements.bool"
    )

    open(filename_save, "w") do f
        x = masks[group][:elements]
        write(f, x)
    end

end


##
