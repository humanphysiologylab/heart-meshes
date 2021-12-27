using ProgressMeter
using SparseArrays
using Graphs
using JSON
using DataFrames
using DelimitedFiles

include("../io/read_binary.jl")
include("../misc/create_stops.jl")
include("../io/load_adj_matrix.jl")
include("../conduction/collect_counts_n_sums.jl")
include("find_rotors.jl")
include("visit_breaks.jl")
# include("../misc/pyplot.jl")
include("create_arrays_subsets.jl")
include("structs.jl")

##

i_heart = 13
adj_matrix =
    load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
# adj_matrix = convert(SparseMatrixCSC{Bool,Int}, adj_matrix)
adj_matrix = convert(SparseMatrixCSC{Float64,Int}, adj_matrix)

##

using SimpleWeightedGraphs
g = SimpleWeightedGraph(adj_matrix)

##

heart_ids = (15,)
group_ids = 1:4
stim_ids = 0:39

df = DataFrame(
    heart = Int[],
    group = Int[],
    stim = Int[],
    index_center = Int[],
    birthtime = Float64[],
    lifetime = Float64[],
)

for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids

    triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

    if !isfile(filename)
        continue
    end

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        @info "no rotors found"
        continue
    end

    filename_save = joinpath("../../data/rotors/jsons_latest/", "$triplet.json")

    for rotor in rotors
        indices = convert.(Int, rotor["indices_points"])
        # indices_subset = randsubseq(indices, 0.5)

        sg, vmap = induced_subgraph(g, indices)
        centrality = betweenness_centrality(sg, 100)
        index_center = vmap[argmax(centrality)]
        # index_center = neighborhood(g, index_center, 1e4)

        rotor["index_center"] = index_center
        delete!(rotor, "indices_points")

        row = Dict(
            "heart" => i_heart,
            "group" => i_group,
            "stim" => i_stim,
            "index_center" => index_center,
            "birthtime" => rotor["t_start"],
            "lifetime" => rotor["lifetime"],
        )

        push!(df, row)

    end

    # write(filename_save, json(rotors))

end


##

writedlm(
    "../../data/rotors/M15_rotor_coordinates.csv",
    Iterators.flatten(([names(df)], eachrow(df))),
    ',',
)

##

i_heart = 15
adj_matrix =
    load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
adj_matrix = convert(SparseMatrixCSC{Float64,Int}, adj_matrix)

using SimpleWeightedGraphs
g = SimpleWeightedGraph(adj_matrix)

mask_rotor = falses(size(adj_matrix, 1))
masks_rotor_groups = [deepcopy(mask_rotor) for i = 1:4]

for i_heart in (i_heart,), i_group = 1:4, i_stim = 0:39

    triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
    filename = joinpath("../../data/rotors/jsons/", "$triplet.json")

    if !isfile(filename)
        continue
    end

    wavebreaks = JSON.parsefile(filename)

    rotors = wavebreaks["rotors"]

    if length(rotors) < 1
        @info "no rotors found"
        continue
    end

    for rotor in rotors
        indices_points = convert.(Int, rotor["indices_points"])
        mask_rotor[indices_points] .= true
        masks_rotor_groups[i_group][indices_points] .= true
    end

end

##

indices_rotor = findall(mask_rotor)
cc = connected_components(g[indices_rotor])
cc = sort(cc, by = length, rev = true)

component_ids = zeros(Int, size(adj_matrix, 1))
for (i, c) in enumerate(cc)
    component_ids[indices_rotor[c]] .= i
end

##

using Tables
using CSV

matrix_mask_rotor = hcat(component_ids, masks_rotor_groups...)

CSV.write(
    "../../data/rotors/M$(i_heart)_rotors_components.csv",
    Tables.table(matrix_mask_rotor, header = ["all", "G1", "G2", "G3", "G4"]),
)

##

using CSV

filename = "../../data/rotors/M15_rotor_coordinates.csv"
df = DataFrame(CSV.File(filename))

##

indices_center = df.index_center
n = length(indices_center)

dist_matrix = Matrix{Float64}(undef, n, n)

@showprogress for (i, index) in enumerate(indices_center)
    ds = dijkstra_shortest_paths(g, index)
    dist_matrix[:, i] = ds.dists[indices_center]
end

##

writedlm("../../data/rotors/M15_rotor_distance_matrix.csv", dist_matrix, ",")

##
