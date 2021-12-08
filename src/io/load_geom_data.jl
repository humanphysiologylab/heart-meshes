include("read_binary.jl")


function load_geometry_data(folder::String)

    points = nothing
    tetra = nothing
    region_points = nothing

    for filename ∈ readdir(folder, join = true)

        if endswith(filename, "3Dpoints.float32")
            points = read_binary(filename, Float32, (3, :))
        elseif endswith(filename, "tetra.int32")
            tetra = read_binary(filename, Int32, (4, :))
            tetra = permutedims(tetra, [2, 1])
        elseif endswith(filename, "points_region.bool")
            region_points = read_binary(filename, Bool, (4, :))
        end

    end

    (; points, tetra, region_points)

end
