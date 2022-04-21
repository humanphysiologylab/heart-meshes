include("../io/load_adj_matrix.jl")
include("../io/load_arrays.jl")

include("../ActivatedGraphs/ActivatedGraphs.jl")
include("../ActArrays/ActArrays.jl")

include("process_arrays.jl")


using Graphs
using StatsBase
using Base.Iterators, Base.Threads
using DataFrames, CSV

op_reduce(x) = takewhile(isfinite, x) |> mean

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

##

heart = 13
folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix)
g = SimpleGraph(A)
a = load_arrays(heart, 1, 13; folder_rheeda)

##

rows = process_arrays(heart, 1, 13; graph=g)
df = DataFrame(rows)

##
############################################
##

hearts = (13, 15)
groups = 1: 4
stims = 0: 39

##

rows_threads = [[] for i in 1:nthreads()]

for heart in hearts

    folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
    A = load_adj_matrix(folder_adj_matrix)
    g = SimpleGraph(A)

    pairs = (collect ∘ product)(groups, stims)
    @threads for (group, stim) in pairs
        t_id = threadid()
        rows_thread = process_arrays(heart, group, stim; graph=g)
        append!(rows_threads[t_id], rows_thread)
        n_thread = length(rows_threads[t_id])
        msg = "$heart-$group-$stim : $(t_id) : $n_thread"
        println(msg)
        # break
    end

end

##

df = DataFrame(
    Iterators.flatten(rows_threads)
)

##


filename_write = joinpath(folder_rheeda, "rotors", "connected-components-fixed.csv")
# CSV.write(filename_write, df)
