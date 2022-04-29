include("../io/load_adj_matrix.jl")
include("../io/load_arrays.jl")

include("../ActArrays/ActArrays.jl")
include("../ActivatedGraphs/ActivatedGraphs.jl")

include("get_component.jl")
include("get_components.jl")

using Graphs, SimpleWeightedGraphs
using StatsBase
using DataFrames, CSV

using Base.Iterators, Base.Threads

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"
folder_save = joinpath(folder_rheeda, "rotors", "cc-4d")
mkpath(folder_save)

heart = 15

folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)
g = SimpleWeightedGraph(A)

##

groups = 1: 4
stims = 0: 39
labels = (collect ∘ product)(groups, stims)

##

@threads for (group, stim) in labels

    t_id = threadid()
    tag = "$heart-$group-$(string(stim, pad=2))"

    filename_save = joinpath(
        folder_save,
        tag * ".csv"
    )
    isfile(filename_save) && continue

    a = load_arrays(heart, group, stim; folder_rheeda)
    maximum(a[:times]) < 7000 && continue

    msg = "$tag : $(t_id)"
    println(msg)

    ag = ActivatedGraph(g, a)

    df = get_components(ag)

    CSV.write(filename_save, df)

    # break

end
