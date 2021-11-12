function calculate_binomial_probas(adjacency_matrix, mask_fibrosis)

    PT = precompute_pascals_triangle(25)  # 24 is largest number of neighbours I've seen
    n_total = sum(adjacency_matrix[mask_fibrosis, :], dims = 2)
    n_fibrosis = sum(adjacency_matrix[mask_fibrosis, mask_fibrosis], dims = 2)
    nk_pairs = zip(n_total .+ 1, n_fibrosis .+ 1)
    probas = map(nk -> PT[nk[1], nk[2]], nk_pairs)
    return probas[:, 1]

end


function calculate_FE_probas(adjacency_matrix, mask_fibrosis, fibrosis_only = false)

    mask = fibrosis_only ? mask_fibrosis : (:)
    n_total = sum(adjacency_matrix[mask, :], dims = 2)
    n_fibrosis = sum(adjacency_matrix[mask, mask_fibrosis], dims = 2)
    probas = n_fibrosis ./ n_total
    probas[mask_fibrosis] = 1 .- probas[mask_fibrosis]
    return probas[:, 1]
end
