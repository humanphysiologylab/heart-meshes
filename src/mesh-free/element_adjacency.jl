using Combinatorics
using SparseArrays
using ProgressMeter

include("../io/load_geom_data.jl")
include("../io/load_adj_matrix.jl")

##

folder = "/Volumes/Samsung_T5/Rheeda/M13"

points, tetra, _ = load_geometry_data(folder)
points = permutedims(points, (2, 1))
tetra .+= 1

##

A = load_adj_matrix(joinpath(folder, "adj_matrix"))

##

# A_tetra = spzeros(Bool, n_tetra, n_tetra)

##

n_points = size(points, 1)
n_tetra = size(tetra, 1)

##

point2tetras = [Int32[] for i in 1:n_points]

@showprogress for (i_tetra, t) in enumerate(eachrow(tetra))
    for i_point in t
        push!(point2tetras[i_point], i_tetra)
    end
end

##

I_tetra = zeros(Int32, n_tetra * 4 * 3 * 2)
J_tetra = zeros(Int32, n_tetra * 4 * 3 * 2)
# 4 - facets
# 3 - points in a facet
# 2 - symmetric relations
# should be trommed after all

n_visited = 0

##

rows = rowvals(A)

@showprogress for i_point ∈ 1: size(A, 1)

    pairs = combinations(
        rows[nzrange(A, i_point)],
        2
    )

    # if i_point % 1_000 == 0
    #     println(i_point)
    # end

    for pair in pairs
        shared_tetras = intersect(point2tetras[[i_point, pair...]]...)

        # @show i_point, pair
        # @show shared_tetras
        
        n_shared = length(shared_tetras)
        @assert n_shared ≤ 2

        if n_shared == 2
            i, j = shared_tetras

            n_visited += 1
            I_tetra[n_visited] = i
            J_tetra[n_visited] = j

            n_visited += 1
            I_tetra[n_visited] = j
            J_tetra[n_visited] = i

            # slow
            # A_tetra[i, j] = A_tetra[j, i] = true
        end
    
    end

end

##

i_first_zero = findfirst(iszero, I_tetra)
@assert i_first_zero == findfirst(iszero, J_tetra)

##

for (letter, X) in zip("IJ", (I_tetra, J_tetra))

    break

    filename_save = joinpath(folder, "$(letter)_tetra.int32")

    open(filename_save, "w") do f
        write(f, X[1 : i_first_zero - 1])
    end

end

##

I_tetra_trim = I_tetra[1: i_first_zero - 1]
J_tetra_trim = J_tetra[1: i_first_zero - 1]

A_tetra = sparse(I_tetra_trim, J_tetra_trim, trues(size(I_tetra_trim)))

##

i = 1
t = points[tetra[i, :], :]

ix = 1
iy = 3

plt = lineplot(t[:, ix], t[:, iy])

for i in rowvals(A_tetra)[nzrange(A_tetra, i)]
    t = points[tetra[i, :], :]
    lineplot!(plt, t[:, ix], t[:, iy])
    scatterplot!(plt, [mean(t[:, ix])], [mean(t[:, iy])], marker=:circle)
end

##
