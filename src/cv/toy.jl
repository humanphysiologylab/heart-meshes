using Graphs, SimpleWeightedGraphs, GraphPlot
include("../rotors/ActivatedGraphs.jl")
using .ActivatedGraphs
using SparseArrays
using StatsBase
include("connect_grads.jl")

using Colors

##

cm = colormap("Blues")

function find_colors(array, cm)

    a_max = maximum(array)
    a_min = minimum(array)

    a_ptp = a_max - a_min

    i_min, i_max = 1, length(cm)
    i_ptp = i_max - i_min

    indices = @. round(Int, (array - a_min) / a_ptp * i_ptp + i_min)

    cm[indices]
        
end

##

nx, ny, nz = 5 * 5, 6 * 5, 2
n = prod([nx, ny, nz])

times_mat = float.(repeat(1:nx, 1, ny, nz))
times_mat = times_mat .+ reshape((1:nz) * 0.1, 1, 1, nz)

for i in 1:ny
    times_mat[:, i, :] .+= 0.1 * (ny / 2. - i) .^ 2
end

times_mat .+= rand(Float64, size(times_mat))

times = times_mat[:]
# colors = find_colors(times, cm);

g = SimpleWeightedDiGraph(grid([nx, ny, nz]))


##
gplothtml(
    g,
    nodefillc=colors,
    nodelabeldist=1.8,
    nodelabelangleoffset=π/4,
    nodelabel=vertices(g)
)


##

starts = 1:nv(g)
stops = starts

points = Iterators.product(1:nx, 1:ny, 1:nz) .|> collect
points = hcat(points[:]...)
points = collect(transpose(float.(points)))

ag_toy = ActivatedGraph(
    sparse(Graphs.weights(g)),
    collect(starts),
    Dict(:times => times),
    Dict(:points => points)
)

##

ag_toy[:is_available] = trues(size(ag_toy[:times]))

pools = find_pools(
    ag_toy;
    is_forward=false,
    ∇t_min = 0, # 1e-3,
    ∇t_max = Inf
)

roots = map(i -> find_root!(pools, i), 1: ag_toy.vectors_len)
root_dict = sort(collect(countmap(roots)), by=x->x[2], rev=true)

ag_rotor = ag_toy
##
