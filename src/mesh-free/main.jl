include("../io/read_binary.jl")
include("../io/load_geom_data.jl")
include("../misc/load_things.jl")
include("./edge_hopping.jl")
using SparseArrays
using Random
# using PlotlyJS

##

folder = "/Volumes/Samsung_T5/Rheeda/M13"

filename_tetra = joinpath(folder, "M13_IRC_tetra.int32")
tetra = read_binary(filename_tetra, Int32, (4, :))
tetra = permutedims(tetra, (2, 1))
tetra .+= 1

filename_points = joinpath(folder, "M13_IRC_3Dpoints.float32")
points = read_binary(filename_points, Float32, (3, :))
points = permutedims(points, (2, 1))

filename_I_tetra = joinpath(folder, "I_tetra.int32")
I_tetra = read_binary(filename_I_tetra, Int32)
filename_J_tetra = joinpath(folder, "J_tetra.int32")
J_tetra = read_binary(filename_J_tetra, Int32)

A_tetra = sparse(I_tetra, J_tetra, trues(size(I_tetra)))

##

n_points = size(points, 1)
rows = rowvals(A_tetra)

i = 1
t = tetra[i, :]

j = rows[nzrange(A_tetra, j)][rand(1: 3)]
for _ in 1: 1000
    j = rows[nzrange(A_tetra, j)][rand(1: 3)]
end

j = rand(1: n_points)

t_neighbor = tetra[j, :]
p = mean(points[t_neighbor, :], dims=1)[1, :]

p .+= rand(eltype(p), size(p))

# i_last, trace = edge_hopping(i, p; points, tetra, A_tetra, save_trace=true)

i_last, trace = edge_hopping(i, p; points=mesh[:points], tetra=mesh.elements, A_tetra=mesh.graph_elements.weights, save_trace=true)
@show length(trace)

##

p_start =  mean(points[t, :], dims=1)[1, :]

i_last = trace[end]
t_last = tetra[i_last, :]
X = points[t_last, :]
p_last = mean(X, dims=1)[1, :]

##

X = []
for t in eachrow(tetra[trace, :])
    c = mean(points[t, :], dims=1)
    push!(X, c)
end
X = vcat(X...)

##

stride = 100

trace_bg = scatter3d(;
    x=points[1: stride: end, 1],
    y=points[1: stride: end, 2],
    z=points[1: stride: end, 3],
    mode="markers",
    marker_size=1,
    # marker_color="grey"
    # colorscale="Greys",
    # marker_color=times_stop[1: stride: end]
)


traces_point = []

for p_draw in (p, p_start, p_last)
    trace = scatter3d(;
        x=[p_draw[1]],
        y=[p_draw[2]],
        z=[p_draw[3]],
        mode="markers",
        marker_size=3,
    )
    push!(traces_point, trace)
end

traces_point = [x for x in traces_point]

trace_trace = scatter3d(;
    x=X[:, 1],
    y=X[:, 2],
    z=X[:, 3],
    mode="lines",
)

plot([trace_bg, traces_point..., trace_trace])

##

ẋ = v(x)
(x_next - x) / dt = v(x)
x_next = x + dt * v(x)
