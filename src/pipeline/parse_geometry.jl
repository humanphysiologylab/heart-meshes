using ArgParse
using SparseArrays
using Distances
using Combinatorics
using ProgressMeter

include("../io/read_binary.jl")


function parse_cl()

    s = ArgParseSettings()

    @add_arg_table s begin
        "--tetra"
            help = "filename. Ex.: tetra.int32"
            required = true
        "--points"
            help = "filename. Ex.: points.float32"
            required = true
        "--output"
            help = "folder to save the results"
            arg_type = String
            default = "./"
    end

    return parse_args(s)

end


function create_adj_vertices(elements::Matrix{T}) where {T}

    ijs = permutations(1:size(elements, 2), 2)

    is = [i for (i, _) in ijs]
    js = [j for (_, j) in ijs]

    Is = elements[:, is][:]
    Js = elements[:, js][:]

    S = sparse(Is, Js, trues(length(Is)))
    S .|= transpose(S)

    return S

end


function create_adj_elements(tetra::Matrix{T}, A_vertices) where {T}

    n_points = maximum(tetra)
    n_tetra = size(tetra, 1)
    tetra_size = size(tetra, 2)

    point2tetras = [T[] for _ in 1:n_points]

    @showprogress for (i_tetra, t) in enumerate(eachrow(tetra))
        for i_point in t
            push!(point2tetras[i_point], i_tetra)
        end
    end

    buff_size = n_tetra * tetra_size * (tetra_size - 1) * 2
    # facets x [points in one facet] x symmetry
    # should be trimmed after all
    I_tetra = zeros(T, buff_size)
    J_tetra = zeros(T, buff_size)

    n_visited = 0

    rows = rowvals(A_vertices)

    @showprogress for i_point ∈ 1: size(A_vertices, 1)

        pairs = combinations(
            rows[nzrange(A_vertices, i_point)],
            2
        )

        for pair in pairs
            shared_tetras = intersect(point2tetras[[i_point, pair...]]...)
            
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

            end
        
        end

    end

    i_first_zero = findfirst(iszero, I_tetra)
    @assert i_first_zero == findfirst(iszero, J_tetra)

    I_tetra_trim = I_tetra[1: i_first_zero - 1]
    J_tetra_trim = J_tetra[1: i_first_zero - 1]

    return I_tetra_trim, J_tetra_trim

end


function main()

    parsed_args = parse_cl()

    filename_tetra = parsed_args["tetra"]
    filename_points = parsed_args["points"]

    tetra = read_binary(filename_tetra, Int32, (4, :))
    tetra = permutedims(tetra, [2, 1])
    minimum(tetra) ≠ 0 && error("minimum element of tetra is not zero")
    tetra .+= 1  # indexing from 1

    points = read_binary(filename_points, Float32, (3, :))
    points = permutedims(points, (2, 1))

    A_vertices = create_adj_vertices(tetra)
    I, J, _ = findnz(A_vertices)
    V = colwise(Euclidean(), points[I, :], points[J, :])

    I_elements, J_elements = create_adj_elements(tetra, A_vertices)

    folder_output = parsed_args["output"]

    folder_vertices = joinpath(folder_output, "adj-vertices")
    mkpath(folder_vertices)

    filename_I = joinpath(folder_vertices, "I.int32")
    filename_J = joinpath(folder_vertices, "J.int32")
    filename_V = joinpath(folder_vertices, "V.float32")

    for (filename, X) in zip(
        (filename_I, filename_J, filename_V),
        (I, J, V)
    )
        open(filename, "w") do f
            write(f, X)
        end

    end

    folder_elements = joinpath(folder_output, "adj-elements")
    mkpath(folder_elements)

    filename_I = joinpath(folder_elements, "I.int32")
    filename_J = joinpath(folder_elements, "J.int32")

    for (filename, X) in zip(
        (filename_I, filename_J),
        (I_elements, J_elements)
    )
        open(filename, "w") do f
            write(f, X)
        end

    end

    @info "success!"

end


main()
