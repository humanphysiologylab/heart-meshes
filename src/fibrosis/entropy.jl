using StatsBase
using SparseArrays


function calculate_FE_probas(
    adjacency_matrix::SparseMatrixCSC,
    mask_fibrosis
)
    n_total = sum(adjacency_matrix[:, :] .> 0, dims = 2)
    n_fibrosis = sum(adjacency_matrix[:, mask_fibrosis] .> 0, dims = 2)
    probas = n_fibrosis ./ n_total
    probas[iszero.(n_total)] .= 0  # no neighbors - no proba
    @assert !any(isnan.(probas)) 
    probas[mask_fibrosis] = 1 .- probas[mask_fibrosis]
    probas = probas[:]
    return probas
end


function calculate_entropy(probas, agg=mean)
    f(p) = iszero(p) ? 0 : -p * log(p)
    agg(map(f, probas))
end


function calculate_entropy(
    adjacency_matrix::SparseMatrixCSC,
    mask_fibrosis
)
    probas = calculate_FE_probas(adjacency_matrix, mask_fibrosis)
    calculate_entropy(probas)
end
