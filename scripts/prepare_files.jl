include("load_files.jl")

##
folder = "/media/andrey/1TBlob/HPL/Data/Rheeda/M15"

##
filename_region = joinpath(folder, "M15_IRC_region.int32")
region = read_binary(filename_region, Int32)

##

using StatsBase
v_counts = countmap(region)

n_regions = length(v_counts)
n_points = size(points)[2]

region_uniques = sort(unique(region))
region_map = Dict(zip(region_uniques, 1:n_regions))

##
region_points = zeros(Bool, (n_regions, n_points))

for column in eachcol(tetra .+ 1)
    for (i_tetra, i_points) in enumerate(column)
        r_i = region[i_tetra]
        r_axis = region_map[r_i]
        region_points[r_axis, i_points] = true
    end
end

##
filename_points_region = joinpath(folder, "M15_IRC_points_region.bool")

open(filename_points_region, "w") do f
    write(f, region_points)
end

##
axes_fibrosis = map(x -> region_map[x], [32, 128])
mask_fibrosis = reduce(.|, eachrow(region_points[axes_fibrosis, :]))

probas = calculate_binomial_probas(S, collect(mask_fibrosis))

filename_binomial_probas = joinpath(folder, "M13_IRC_binomial_probas.Float64")

open(filename_binomial_probas, "w") do f
    write(f, probas)
end

##

filename_points = joinpath(folder, "M15_IRC_3Dpoints.float32")
points = read_binary(filename_points, Float32, (3, :))


##

filename_tetra = joinpath(folder, "M15_IRC_tetra.int32")
tetra = read_binary(filename_tetra, Int32, (4, :))
tetra = permutedims(tetra, [2, 1])

##
S = create_adjacency_matrix(tetra)

##
filename_I = joinpath(folder, "I.int32")
filename_J = joinpath(folder, "J.int32")

##
I, J, V = findnz(S)

open(filename_I, "w") do f
    write(f, I)
end

open(filename_J, "w") do f
    write(f, J)
end

##
region_unique = unique(region_points)
v_counts = value_counts(region)
region_map = Dict(zip(region_uniques, 1:n_regions))

##

region_id = 128  # 32 or 128
region_number = region_map[region_id]
indices_region = findall(region_points[region_number, :])

S_region = S[indices_region, indices_region]

##
components = find_connected_components(S_region)

##
filename_components = joinpath(folder, "connected_components_id$region_id.txt")

open(filename_components, "w") do f
    for c in components
        indices_native = indices_region[collect(c)]
        line = join(string.(indices_native), " ")
        write(f, line * "\n")
    end
end

##
using Distances

I, J, V = findnz(S)
edge_weights = colwise(Euclidean(), points[:, I], points[:, J])
adj_matrix = sparse(I, J, edge_weights)

##
filename_weights = joinpath(folder, "edge_weights.float32")

open(filename_weights, "w") do f
    write(f, edge_weights)
end

##
