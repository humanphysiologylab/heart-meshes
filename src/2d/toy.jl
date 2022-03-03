using Graphs, SimpleWeightedGraphs, GraphPlot
include("../rotors/ActivatedGraphs.jl")
using .ActivatedGraphs
using SparseArrays
using StatsBase
include("../cv/connect_grads.jl")
include("../io/read_binary.jl")

##

nx = ny = 500 ÷ 1
g = SimpleWeightedDiGraph(grid([nx, ny]))

##

filename_starts = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/2d/G4_starts.int"
starts = read_binary(filename_starts, Int)

filename_times = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/2d/G4_times.float"
times = read_binary(filename_times, Float64)  # .|> float

h = 100. * 1 # um
points = Iterators.product(1:nx, 1:ny) .|> collect
points = hcat(points[:]...)
points = collect(transpose(float.(points)))

points .*= h

ag = ActivatedGraph(
    sparse(Graphs.weights(g)),
    collect(starts),
    Dict(:times => times),
    Dict(:points => points)
)

##
include("../cv/find_trajectory.jl")

times_max, i = findmax(ag[:times])
# i = 2
trajectory = find_trajectory(i, g=ag, ∇t_min=0., ∇t_max=0.01)

vs = [find_vertex_id(ag, i) for i in trajectory]
X = ag[:points][vs, :]
times = ag[:times][trajectory]

##

using DataFrames, CSV

filename_save = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/2d/G4_grad.csv"

df = DataFrame(:t => times, :x => X[:, 1], :y => X[:, 2])
CSV.write(filename_save, df)

##

roots = map(i -> find_root!(pools, i), 1: ag_toy.vectors_len)
root_dict = sort(collect(countmap(roots)), by=x->x[2], rev=true)

ag_rotor = ag_toy
##
