using SparseArrays
include("read_binary.jl")


function load_adj_matrix(folder::String, incidence_only::Bool = true)
    filename_I = joinpath(folder, "I.int32")
    filename_J = joinpath(folder, "J.int32")

    I = read_binary(filename_I, Int32)
    J = read_binary(filename_J, Int32)

    if incidence_only
        V = trues(length(I))
    else
        filename_V = joinpath(folder, "V.float32")
        V = read_binary(filename_V, Float32)
    end

    adj_matrix = sparse(vcat(I, J), vcat(J, I), vcat(V, V))

end
