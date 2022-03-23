using SparseArrays
include("read_binary.jl")


function load_adj_matrix(
    folder::String,
    incidence_only::Bool = true;
    IntType = Int32,
    FloatType = Float32
)
    I, J, V = load_IJV(folder, incidence_only; IntType, FloatType)
    n_I = maximum(I)
    n_J = maximum(J)
    n = max(n_I, n_J)
    combine = (x, y) -> x
    adj_matrix = sparse(vcat(I, J), vcat(J, I), vcat(V, V), n, n, combine)
end


function load_IJV(
    folder::String,
    incidence_only::Bool = true;
    IntType = Int32,
    FloatType = Float32
)

    filename_I = nothing
    filename_J = nothing
    filename_V = nothing

    for filename in readdir(folder, join = true)
        if occursin("/I.", filename)
            filename_I = joinpath(filename)
        elseif occursin("/J.", filename)
            filename_J = joinpath(filename)
        elseif occursin("/V.", filename)
            filename_V = joinpath(filename)
        end
    end

    if any(isnothing.([filename_I, filename_J]))
        error("invalid dir")
    end

    I = read_binary(filename_I, IntType)
    J = read_binary(filename_J, IntType)

    if incidence_only
        V = trues(length(I))
    else
        V = read_binary(filename_V, FloatType)
    end

    I, J, V

end
