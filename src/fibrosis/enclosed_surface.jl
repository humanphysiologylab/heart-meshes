using Graphs, SimpleWeightedGraphs
using ProgressMeter
using StatsBase
using DataFrames, CSV
using NearestNeighbors

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("./entropy.jl")

include("../ActArrays/ActArrays.jl")

##

function mean_w(x, w)
    sum(x .* w) / sum(w)
end

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

filename_region = joinpath(folder_rheeda, "M$heart", "M$(heart)_IRC_region.int32")
region = read_binary(filename_region, Int32)
fibrosis_elements = region .∈ Ref((32, 128))
fibrosis_elements = collect(fibrosis_elements)

##

filename_volume = joinpath(folder_geometry, "element_volume.float32")
volume = read_binary(filename_volume, Float32)

##

filename_fibrosis = joinpath(folder_rheeda, "geometry", "M$heart", "mask_fibrosis.bool")
mask_fibrosis = read_binary(filename_fibrosis, Bool)

##

tree = kdtree = KDTree(points)
nn(tree, points[:, :])

##

filename_meta = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet.csv"
folder_trajectories = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet"

df_meta = CSV.read(filename_meta, DataFrame)

##

# filename_probas = "/Users/andrey/Work/HPL/projects/rheeda/multiscale-personalized-models/data/averaging/averaging.csv"
# df_probas = CSV.read(filename_probas, DataFrame)

##

filename_probas = "/Users/andrey/Work/HPL/projects/rheeda/multiscale-personalized-models/data/probas-vertex-wise.csv"
df_probas = CSV.read(filename_probas, DataFrame)

##

columns_proba = ("P(wb | act)", "P(wb)", "P(act)")

for c in columns_proba
    mask_ismissing = ismissing.(df_probas[:, c])
    df_probas[mask_ismissing, c] .= 0
end

##

# ρs = 10 .^ (1: 0.1: 5)
ρs = [1e5]
threshold = 5000  # um

# rows = []
rows_threads = [[] for i in 1:Threads.nthreads()]

USE_QUANTILES = false
n_quantiles = 9

# Threads.@threads for row_meta in eachrow(df_meta[df_meta.heart .== heart, :])
for row_meta in eachrow(df_meta[df_meta.heart .== heart, :])

    t_id = Threads.threadid()

    # row_meta.heart ≠ heart && continue
    
    group = row_meta.group
    stim = row_meta.stim
    i = row_meta.i

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

    mask_probas = df_probas.heart .== heart_id
    mask_probas .&= df_probas.group .== group

    df_group = df_probas[mask_probas, :]

    # if (t_id, heart, group, stim, i) == (8, 15, 4, 25, 0) 
    #     continue
    # end

    @show t_id, heart, group, stim, i

    for ρ in ρs

        mask_dist = dists .< ρ
        mask_dist .&= mask_rotor_environment

        indices_dist = findall(mask_dist)
        indices_els = [get_el(idx_mapper, i) for i in indices_dist] |> Iterators.flatten |> unique
        fibrosis_mean_el = mean_w(
            fibrosis_elements[indices_els],
            volume[indices_els]
        )

        vertices = elements[indices_els, :]

        fibrosis_intersection = mask_fibrosis[mask_dist] 
        fibrosis_mean = fibrosis_intersection |> mean

        fibrosis_entropy = calculate_entropy(
            A[mask_dist, mask_dist],
            mask_fibrosis[mask_dist]
        )

        row = Dict(
            "heart" => heart,
            "group" => group,
            "stim" => stim,
            "i" => i,
            "ρ" => ρ,
            "fibrosis_mean" => fibrosis_mean,
            "fibrosis_entropy" => fibrosis_entropy,
            "fibrosis_mean_el" => fibrosis_mean_el
        )

        if USE_QUANTILES

            qs = nquantile(fibrosis_intersection, n_quantiles)

            for (iq, q) in enumerate(qs)
                c = "fibrosis_q$(iq)_$(n_quantiles + 1)"
                if iq == 1
                    c = "fibrosis_min"
                elseif iq == n_quantiles + 1
                    c = "fibrosis_max"
                end
                row[c] = q
            end

        end

        #
        # mask_intersect = mask_dist[df_group.i]
        # df_intersect = df_group[mask_intersect, :]

        # @show size(mask_dist)
        # @show df_po

        df_intersect = df_group[mask_dist, :]

        #
        # indices_dist_intersect = intersect(indices_dist, df_group.i)

        for column_proba in columns_proba
            proba = df_intersect[: , column_proba]

            row["$(column_proba)_mean"] = mean(proba)
            row["$(column_proba)_sum"] = sum(proba)

            proba_full = df_group[:, column_proba]
            proba_el = mean(proba_full[vertices], dims=2)[:]

            proba_el_mean = mean_w(proba_el, volume[indices_els])
            row["$(column_proba)_mean_el"] = proba_el_mean

            if USE_QUANTILES

                qs = nquantile(proba, n_quantiles)

                for (iq, q) in enumerate(qs)
                    c = "$(column_proba)_q$(iq)_$(n_quantiles + 1)"
                    if iq == 1
                        c = "$(column_proba)_min"
                    elseif iq == n_quantiles + 1
                        c = "$(column_proba)_max"
                    end
                    row[c] = q
                end

            end

        end

        # push!(rows, row)
        push!(rows_threads[t_id], row)

    end

end

##

rows = Iterators.flatten(rows_threads)
df = DataFrame()

for key in rows |> first |> keys

    v = [row[key] for row in rows]
    s_key = string(key)
    df[:, s_key] = v

end

##

df

##

columns_sorted = names(df) |> sort
df = df[!, columns_sorted]

##

# df = DataFrame(rows)
# df = DataFrame(
#     Iterators.flatten(rows_threads)
# )

##

# filename_save = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet-averaging-$heart-v3.csv"
filename_save = "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet-averaging-$heart-v3-el.csv"
CSV.write(filename_save, df)

##


##

group = 3
stim = 13

filename_traj = joinpath(
    "/Volumes/samsung-T5/HPL/Rheeda/rotors/unet/",
    string(heart),
    string(group),
    string(stim),
    string(0, pad=3) * ".csv"
)

traj = CSV.read(filename_traj, DataFrame)

##

X = traj[:, [:x, :y, :z]] |> Matrix |> transpose
nn_indices = nn(tree, X) |> first

ds = dijkstra_shortest_paths(g, nn_indices)

threshold = 5000
mask_space = ds.dists .< threshold
indices_out = findall(.!mask_space)

g_mask = g[indices_out]

cc = connected_components(g_mask)
length_max = maximum(length.(cc))

for (i, c) in enumerate(cc)
    length(c) == length_max && continue
    mask_space[indices_out[c]] .= true
end

filename_save = joinpath(
    "/Users/andrey/Work/HPL/projects/rheeda/multiscale-personalized-models/data/tmp",
    "mask.int"
)
# write(filename_save, collect(mask_space)) 


##


nn_indices_subset = nn_indices[1:10:end]

dists_cum = zeros(eltype(g.weights), size(points, 2))

@showprogress for i in nn_indices_subset
    ds = dijkstra_shortest_paths(g, i)
    dists = ds.dists
    dists_cum .+= dists
end

filename_save = joinpath(
    "/Users/andrey/Work/HPL/projects/rheeda/multiscale-personalized-models/data/tmp",
    "dists.float32"
)
write(filename_save, dists_cum)


dists = ds.dists

milestones = 10 .^ (1: 0.25: 5)

x = []

for h in milestones

    mean_fibrosis = mask_fibrosis[dists .< h] |> mean
    push!(x, mean_fibrosis)

end

##
