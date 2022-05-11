using SparseArrays

include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")


function load_geometry(folder_geometry)

    filename_tetra = joinpath(folder_geometry, "tetra.int32")
    tetra = read_binary(filename_tetra, Int32, (4, :))
    tetra = permutedims(tetra, (2, 1))
    tetra .+= 1

    filename_points = joinpath(folder_geometry, "points.float32")
    points = read_binary(filename_points, Float32, (3, :))
    points = permutedims(points, (2, 1))

    filename_I_tetra = joinpath(folder_geometry, "adj-elements/I.int32")
    I_tetra = read_binary(filename_I_tetra, Int32)
    filename_J_tetra = joinpath(folder_geometry, "adj-elements/J.int32")
    J_tetra = read_binary(filename_J_tetra, Int32)

    A_tetra = sparse(I_tetra, J_tetra, ones(size(I_tetra)))
    A_tetra.nzval .= 1

    A_vertices = load_adj_matrix(joinpath(folder_geometry, "adj-vertices"), false)

    return A_vertices, A_tetra, tetra, points

end
