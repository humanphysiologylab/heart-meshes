include("../io/load_adj_matrix.jl")
include("../io/load_arrays.jl")

include("../ActivatedGraphs/ActivatedGraphs.jl")
include("../ActArrays/ActArrays.jl")

include("process_component.jl")

using Graphs
using StatsBase
using Base.Iterators, Base.Threads
using DataFrames, CSV

op_reduce(x) = takewhile(isfinite, x) |> mean

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

##

function process_arrays(
    heart::Integer,
    group::Integer,
    stim::Integer;
    graph::SimpleGraph,
    folder_rheeda=folder_rheeda,
    component_length_min = 100
)

    a = load_arrays(heart, group, stim; folder_rheeda)

    c_mean = reduce(a, :conduction, op_reduce)
    indices_breaks = findall(c_mean .< 1.)
    cc = connected_components(graph[indices_breaks])
    cc = sort(cc, by=length, rev=true)
    cc = [indices_breaks[c] for c in cc]

    rows = []
    for (i, component) in enumerate(cc)
        length(component) < component_length_min && continue
        rows_component = process_component(component, a, dt_max=50.)
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

    rows

end

##

heart = 15
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


filename_write = joinpath(folder_rheeda, "rotors", "connected_components.csv")
# CSV.write(filename_write, df)
