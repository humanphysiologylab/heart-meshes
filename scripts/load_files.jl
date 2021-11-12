include("load_src.jl")


function load_files(folder::String)

    points = nothing
    tetra = nothing
    region_points = nothing
    S = nothing

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

        if isfile(filename_I) && isfile(filename_J)

            I = read_binary(filename_I, Int32)
            J = read_binary(filename_J, Int32)
            V = ones(Bool, length(I))

            S = sparse(I, J, V)
            S .|= transpose(S)

        end

    end

    (; points, tetra, region_points, S)

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
