using Graphs, SimpleWeightedGraphs
using ProgressMeter
using Random
using Statistics
using OrderedCollections
using DataFrames, CSV

include("../misc/graph.jl")
include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")

##

include("../ActArrays/ActArrays.jl")
include("../io/load_arrays.jl")
# function load_arrays(h::Integer, g::Integer, s::Integer; folder_rheeda)

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

function collect_data(
    h::Integer, g::Integer, s::Integer;
    folder_rheeda,
    vertices::Vector{<:Integer},
    time_stop=2500.
)

    a = load_arrays(h, g, s; folder_rheeda)

    result = Dict{Int, Vector{Vector{Float32}}}()

    for v in vertices
        t = get_subarray(a, v, :times)
        c = get_subarray(a, v, :conduction)
        i_last = searchsortedlast(t, time_stop)

        dt_ = diff(t[1: i_last])
        c_ = c[2: i_last]
        
        result[v] = [dt_, c_]
    end

    result

end


##

using JSON

n_points_dict = Dict(
    13 => Int32(1958268),
    15 => Int32(2432365)
)

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda"
folder_write = joinpath(folder_rheeda, "conduction-dt")

hearts = (13, 15)
groups = (1, 2, 3, 4)
stims = 0: 39

n_samples = 10_000

pairs = Iterators.product(hearts, groups) |> collect

Threads.@threads for (heart, group) in pairs

    n_points = n_points_dict[heart]
    samples = randperm(MersenneTwister(1234), n_points)[1:n_samples]

    result = Dict{Integer, Any}()

    @showprogress for stim in stims
        x = collect_data(heart, group, stim; folder_rheeda, vertices=samples)
        result[stim] = x
    end

    filename_save = joinpath(folder_write, "M$heart-G$group.json")
    text = JSON.json(result)
    write(filename_save, text)

end
