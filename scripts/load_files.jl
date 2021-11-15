using SparseArrays

include("../src/read_binary.jl")


function load_files(folder::String)

    points = nothing
    tetra = nothing
    region_points = nothing
    adj_matrix = nothing

    for filename ∈ readdir(folder, join = true)

        if endswith(filename, "3Dpoints.float32")
            points = read_binary(filename, Float32, (3, :))
        elseif endswith(filename, "tetra.int32")
            tetra = read_binary(filename, Int32, (4, :))
            tetra = permutedims(tetra, [2, 1])
        elseif endswith(filename, "points_region.bool")
            region_points = read_binary(filename, Bool, (4, :))
        end

        filename_I = joinpath(folder, "I.int32")
        filename_J = joinpath(folder, "J.int32")
        filename_V = joinpath(folder, "edge_weights.float32")

        if all(isfile, (filename_I, filename_J, filename_V))

            I = read_binary(filename_I, Int32)
            J = read_binary(filename_J, Int32)
            edge_weights = read_binary(filename_V, Float32)

            adj_matrix = sparse(vcat(I, J), vcat(J, I), vcat(edge_weights, edge_weights))
        end

    end

    (; points, tetra, region_points, adj_matrix)

end


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
