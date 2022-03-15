using Combinatorics
using SparseArrays
using ProgressMeter
using Distances
using Graphs, SimpleWeightedGraphs

include("../io/load_geom_data.jl")
include("../io/load_adj_matrix.jl")
include("../io/read_binary.jl")

##

folder = "/home/andrey/WORK/HPL/projects/rheeda/publication/data/2d"

suffix = "2000um"


filename_points = joinpath(folder, "G4_points_$(suffix)_jitter.float")
points = read_binary(filename_points, Float64, (2, :))
points = permutedims(points, (2, 1))

filename_elements = joinpath(folder, "G4_elements_$(suffix).int")
elements = read_binary(filename_elements, Int, (3, :))
elements = permutedims(elements, (2, 1))
elements .+= 1

filename_edges = joinpath(folder, "G4_edges_$(suffix).int")
edges = read_binary(filename_edges, Int, (2, :))
edges = permutedims(edges, (2, 1))
edges .+= 1

##

I = edges[:, 1]
J = edges[:, 2]

W_up = colwise(
    Euclidean(),
    transpose(points[I, :]),
    transpose(points[J, :])
)

##

g = SimpleWeightedGraph(
    I,
    J,
    W_up
    # fill(dh, size(edges, 1))
)

##

A = g.weights

# A_tetra = spzeros(Bool, n_tetra, n_tetra)

##

n_points = size(points, 1)
n_elements = size(elements, 1)

##

point2element = [Int[] for i in 1:n_points]

@showprogress for (i_element, element) in enumerate(eachrow(elements))
    for i_point in element
        push!(point2element[i_point], i_element)
    end
end

##

I_element = zeros(Int, n_elements * 3 * 2 * 2)
J_element = zeros(Int, n_elements * 3 * 2 * 2)
# 3 - edges
# 2 - points in an edge
# 2 - symmetric relations
# should be trimmed after all

n_visited = 0

##

rows = rowvals(A)

@showprogress for i_point ∈ 1: size(A, 1)

    # pairs = combinations(
    #     rows[nzrange(A, i_point)],
    #     2
    # )

    # if i_point % 1_000 == 0
    #     println(i_point)
    # end

    for j_point in rows[nzrange(A, i_point)]  # neighbors
        pair = [i_point, j_point]
        elements_pair = point2element[pair]
        shared_elements = intersect(elements_pair...)

        # @show pair
        # @show elements_pair
        # @show shared_elements
        
        n_shared = length(shared_elements)
        @assert n_shared ≤ 2

        if n_shared == 2
            i_element, j_element = shared_elements

            n_visited += 1
            I_element[n_visited] = i_element
            J_element[n_visited] = j_element

            n_visited += 1
            I_element[n_visited] = j_element
            J_element[n_visited] = i_element

            # slow
            # A_tetra[i, j] = A_tetra[j, i] = true
        end
    
    end

end

##

i_first_zero = findfirst(iszero, I_element)
@assert i_first_zero == findfirst(iszero, J_element)

##

for (letter, X) in zip("IJ", (I_element, J_element))

    @show filename_save = joinpath(folder, "G4_$(letter)_element_$(suffix).int32")

    # continue

    open(filename_save, "w") do f
        write(f, X[1 : i_first_zero - 1])
    end

end

##

I_element_trim = I_element[1: i_first_zero - 1]
J_element_trim = J_element[1: i_first_zero - 1]

A_element = sparse(I_element_trim, J_element_trim, trues(size(I_element_trim)))

##

i = 1
t = points[elements[i, :], :]

ix = 1
iy = 2

plt = lineplot(t[:, ix], t[:, iy])
scatterplot!(plt, [mean(t[:, ix])], [mean(t[:, iy])], marker=:circle)

for i in rowvals(A_element)[nzrange(A_element, i)]
    t = points[elements[i, :], :]
    lineplot!(plt, t[:, ix], t[:, iy])
    scatterplot!(plt, [mean(t[:, ix])], [mean(t[:, iy])], marker=:circle)
end

plt
