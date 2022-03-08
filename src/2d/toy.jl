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

suffix = "_100uM_jitter"

##

filename_starts = "../2d/G4_starts$suffix.int"
starts = read_binary(filename_starts, Int)

filename_times = "../2d/G4_times$suffix.float"
times = read_binary(filename_times, Float64)  # .|> float

##

h = 100. * 1 # um
points = Iterators.product(1:nx, 1:ny) .|> collect
points = hcat(points[:]...)
points = collect(transpose(float.(points)))

points .*= h

##

filename_points = "../2d/G4_points$suffix.float"
points = read_binary(filename_points, Float64, (2, :))
points = permutedims(points, (2, 1))  # .|> float

##
using DelimitedFiles
edges = readdlm("../2d/G4_edges$suffix.txt", ' ', Int, '\n')
edges .+= 1

##

using Distances
W_up = colwise(
    Euclidean(),
    transpose(points[edges[:, 1], :]),
    transpose(points[edges[:, 2], :])
)


##

dh = 100.  # um
g = SimpleWeightedGraph(
    edges[:, 1],
    edges[:, 2],
    W_up
    # fill(dh, size(edges, 1))
)

##

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

filename_save = "../2d/G4_trajectory_grad$suffix.csv"

df = DataFrame(:t => times, :x => X[:, 1], :y => X[:, 2])
CSV.write(filename_save, df)

##

roots = map(i -> find_root!(pools, i), 1: ag_toy.vectors_len)
root_dict = sort(collect(countmap(roots)), by=x->x[2], rev=true)

ag_rotor = ag_toy
##
