include("load_src.jl")

##
# folder = "/media/andrey/1TBlob/HPL/Data/Rheeda/M15"
folder = "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M13/"

##
filename_points = joinpath(folder, "M13_IRC_3Dpoints.float32")
points = read_binary(filename_points, Float32, (3, :))

##
filename_tetra = joinpath(folder, "M13_IRC_tetra.int32")
tetra = read_binary(filename_tetra, Int32, (4, :))
tetra = permutedims(tetra, [2, 1])

##
filename_points_region = joinpath(folder, "M13_IRC_points_region.bool")
region_points = read_binary(filename_points_region, Bool, (4, :))

##
filename_I = joinpath(folder, "I.int32")
filename_J = joinpath(folder, "J.int32")

I = read_binary(filename_I, Int32)
J = read_binary(filename_J, Int32)
V = ones(Bool, length(I))

S = sparse(I, J, V)
S .|= transpose(S)


##
function load_connected_components(region_id, folder)

    filename_components = joinpath(folder, "connected_components_id$region_id.txt")

    components = Set{Set{Int}}()
    open(filename_components) do f
        lines = split(read(f, String), "\n")
        for line in lines
            if length(line) > 0
                indices = map(x -> parse(Int, x), split(line))
                s = Set(indices)
                push!(components, s)
            end
        end
    end

    return components

end
