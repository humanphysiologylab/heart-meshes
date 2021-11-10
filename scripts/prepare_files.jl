include("load_src.jl")
include("load_files.jl")

##
folder = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M13/"

##

filename_region = joinpath(folder, "M13_IRC_region.int32")
region = read_binary(filename_region, Int32)

##

v_counts = value_counts(region)

region_uniques = sort(unique(region))
region_map = Dict(zip(region_uniques, 1:n_regions))

n_regions = length(v_counts)
n_points = size(points)[2]

region_points = zeros(Bool, (n_regions, n_points))

for column in eachcol(tetra .+ 1)
    for (i_tetra, i_points) in enumerate(column)
        r_i = region[i_tetra]
        r_axis = region_map[r_i]
        region_points[r_axis, i_points] = true
    end
end

##
filename_points_region = joinpath(folder, "M13_IRC_points_region.bool")

open(filename_points_region, "w") do f
    write(f, region_points)
end

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
