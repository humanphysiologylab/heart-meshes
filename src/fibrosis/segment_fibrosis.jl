using DataFrames, CSV
using Graphs, SimpleWeightedGraphs
using DataStructures

include("../io/load_adj_matrix.jl")
include("../misc/graph.jl")

##

i_heart = 13
adj_matrix =
    load_adj_matrix("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix", false)
g = SimpleWeightedGraph(adj_matrix)

##

df = DataFrame(CSV.File("../../data/rotors/M13-all-r1e4-srcs.csv"))
df = df[1:10:end]

##
srcs = df[!, :vertex_id]
ds, adj_matrix_srcs = dijkstra_many_sourses_v2(g, srcs)
adj_matrix_srcs .|= transpose(adj_matrix_srcs)

##

I, J = findnz(adj_matrix_srcs)[1:end-1]

open("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/I_metrics.int64", "w") do f
    write(f, I)
end

open("/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/J_metrics.int64", "w") do f
    write(f, J)
end

##

adj_matrix_srcs = load_adj_matrix(
    "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/adj_matrix_srcs",
    IntType = Int,
    FloatType = Float64,
)

##

fd = df."fibrosis-density"
mask_available = fd .> 1e-2
g_srcs = SimpleGraph(adj_matrix_srcs)

##

ds = dijkstra_many_sourses(g, srcs)


##

srcs_sets = DisjointSets{eltype(srcs)}(srcs)

function find_steepest_neighbours(src, df, g_srcs)

    ns = neighbors(g_srcs, src)
    df_ns = df[df.vertex_id.∈(ns,), :]

    fd_neighbour, i_neighbour = findmax(df_ns[:, "fibrosis-density"])
    i_neighbour = df_ns.vertex_id[i_neighbour]

    return fd_neighbour, i_neighbour

end


for src in srcs

    fd_current = df[findfirst(==(src), df.vertex_id), "fibrosis-density"]

    if fd_current < 0.2
        continue
    end

    fd_neighbour, i_neighbour = find_steepest_neighbours(src, df, g_srcs)

    if fd_neighbour > fd_current || fd_neighbour > 0.3
        union!(srcs_sets, src, i_neighbour)
    end

end

##

roots = map(i -> find_root(srcs_sets, i), srcs)

##

df.roots = roots
true_roots = collect(keys(filter(x -> last(x) > 1, countmap(roots))))

df[df.roots.∉(true_roots,), :roots] .= -1

roots_fd = combine(groupby(df, :roots), "fibrosis-density" => mean)
roots_fd = Dict(zip(roots_fd[:, 1], roots_fd[:, 2]))

df.roots_fd = map(x -> roots_fd[x], df.roots)

CSV.write("../../data/rotors/M13-r1e4-srcs-roots.csv", df[:, [:vertex_id, :roots]])

##

df_interp = DataFrame()
n_points = size(adj_matrix, 1)
columns = "roots", "fibrosis-density", "vertex_id", "roots_fd"

for c in columns
    v = sparsevec(df[!, :vertex_id], df[!, c], n_points)
    df_interp[!, c] = v[ds.parents]
end

##

CSV.write("../../data/rotors/M13-r1e4-roots-interp.csv", df_interp)
