using SparseArrays


function calculate_FE_probas(
    adjacency_matrix::SparseMatrixCSC{Bool,T},
    mask_fibrosis,
    fibrosis_only = false,
) where {T<:Integer}
    mask = fibrosis_only ? mask_fibrosis : (:)
    n_total = sum(adjacency_matrix[mask, :], dims = 2)
    n_fibrosis = sum(adjacency_matrix[mask, mask_fibrosis], dims = 2)
    probas = n_fibrosis ./ n_total
    probas[mask_fibrosis] = 1 .- probas[mask_fibrosis]
    return probas[:, 1]
end


function calculate_entropy(probas)
    indices_zero = iszero.(probas)
    probas_nonzero = @view probas[.!indices_zero]
    sum(map(p -> -p * log(p), probas_nonzero))
end
