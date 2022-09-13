using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics
using OrderedCollections
using DataFrames, CSV

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

include("../ActArrays/ActArrays.jl")

include("../fibrosis/entropy.jl")

##

function mean_w(x, w)
    sum(x .* w) / sum(w)
end

##

# heart  group
# 13     1        0
#        2        0
#        3        0
#        4        0
# 15     1        0
#        2        8
#        3        6
#        4        4
n_broken_simulations = Dict(
    13 => [0, 0, 0, 0],
    15 => [0, 8, 6, 4]
)
n_stim = 12
n_simulations = 40

##

heart = 13

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"
folder_geometry = joinpath(folder_rheeda, "geometry", "M$heart")

folder_adj_matrix = joinpath(folder_geometry, "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)
g = SimpleWeightedGraph(A)

folder_adj_matrix_el = joinpath(folder_geometry, "adj-elements")
A_elements = load_adj_matrix(folder_adj_matrix_el)

##

folder_conduction = joinpath(
    folder_rheeda,
    "conduction-cumulative"
)

arrays = Dict{Int, Dict{Symbol, Vector}}()

for group in 1: 4

    tag = "M$heart-G$group"

    filename_transmission = joinpath(folder_conduction, "transmission-$tag.int32")
    filename_activation = joinpath(folder_conduction, "activation-$tag.int32")

    transmission = read_binary(filename_transmission, Int32)
    activation = read_binary(filename_activation, Int32)

    @assert (activation .>= transmission) |> all
    @assert iszero.(transmission[iszero.(activation)]) |> all 

    arrays[group] = Dict(
        :transmission => transmission,
        :activation => activation,
    )

end

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

filename_mask_fibrosis = joinpath(folder_rheeda, "geometry", "M$heart", "mask_fibrosis.bool")
fd = read_binary(filename_mask_fibrosis, Bool)

##

folder_mask_rotors = "/Volumes/samsung-T5/HPL/Rheeda/mask_rotors"

masks_rotors = Dict()

for group in 1: 4

    masks_rotors[group] = Dict()

    filename = joinpath(
        folder_mask_rotors,
        "$(heart)-$(group)-vertices--torus.bool"
    )
    mask = read_binary(filename, Bool)
    masks_rotors[group][:vertices] = mask

    filename = joinpath(
        folder_mask_rotors,
        "$(heart)-$(group)-elements--torus.bool"
    )
    mask = read_binary(filename, Bool)
    masks_rotors[group][:elements] = mask

end



##

n_points = size(A, 1)
n_samples = 10_000
samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]

ρs = (1e3, 1e4)
# ρ = 1e4

groups = 1: 4
n_groups = length(groups)

rows_threads = [[] for i in 1:Threads.nthreads()]

# @showprogress for (i, vertex_id) ∈ collect(enumerate(samples))
Threads.@threads for vertex_id ∈ samples

    t_id = Threads.threadid()

    if t_id == 1
        n_rows = sum(length.(rows_threads))
        n_rows % 100 == 0 && print(".")
    end


    for ρ in ρs

        neighbours = neighborhood(g, vertex_id, ρ)
        n_points_area = length(neighbours)

        indices_els = [get_el(idx_mapper, i) for i in neighbours] |> Iterators.flatten |> unique
        
        fd = mean_w(
            fibrosis_elements[indices_els],
            volume[indices_els]
        )

        fibrosis_entropy = calculate_entropy(
            A_elements[indices_els, indices_els],
            fibrosis_elements[indices_els]
        )

        indices_vertices = elements[indices_els, :]

        for group in groups
            
            # trans = arrays[group][:transmission][neighbours]
            # act = arrays[group][:activation][neighbours]
            # wb = act .- trans

            # n_valid_simulations = n_simulations - n_broken_simulations[heart][group]
            # n = n_points_area * n_valid_simulations * n_stim

            # p_act = sum(act) / n
            # p_wb = sum(wb) / n
            # p_wb_cond_act = p_wb / p_act

            trans = mean(arrays[group][:transmission][indices_vertices], dims=2)[:]
            act  = mean(arrays[group][:activation][indices_vertices], dims=2)[:]
            wb = act .- trans

            n_valid_simulations = n_simulations - n_broken_simulations[heart][group]
            n = n_valid_simulations * n_stim

            p_act = mean_w(act, volume[indices_els]) / n
            p_wb = mean_w(wb, volume[indices_els]) / n
            p_wb_act = p_wb / p_act

            rotorness = mean_w(
                masks_rotors[group][:elements][indices_els],
                volume[indices_els]
            )

            row = Dict(
                :i => vertex_id,
                :ρ => ρ,

                :heart => heart,
                :group => group,

                :fd => fd,
                :fe => fibrosis_entropy,

                :p_act => p_act,
                :p_wb_act => p_wb_act,
                :p_wb => p_wb,

                :rotorness => rotorness
            )

            push!(rows_threads[t_id], row)

        end  # for group in groups

    end  # for ρ in ρs

end

rows = Iterators.flatten(rows_threads)
df = DataFrame(rows)

##

folder_save = joinpath(folder_rheeda, "averaging")
filename_csv = joinpath(folder_save, "M$heart-$n_samples-elements-rotorness-torus-latest.csv")

CSV.write(filename_csv, df)
