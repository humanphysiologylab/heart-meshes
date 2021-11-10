function unique_indices(x::AbstractArray{T}) where {T}
    # https://stackoverflow.com/a/50900113/13213091
    uniqueset = Set{T}()
    ex = eachindex(x)
    idxs = Vector{eltype(ex)}()
    for i in ex
        xi = x[i]
        if !(xi in uniqueset)
            push!(idxs, i)
            push!(uniqueset, xi)
        end
    end
    idxs
end


function value_counts(array)
    uniques = unique(array)
    counts = [sum(isequal.(x, array)) for x in uniques]
    Dict(zip(uniques, counts))
end
