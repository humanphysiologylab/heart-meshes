function proba_binomial(n, k)
    binomial(n, k) / 2^n
end


function precompute_pascals_triangle(n_max)
    P = zeros(n_max + 1, n_max + 1)
    for n = 0:n_max, k = 0:n
        P[n+1, k+1] = proba_binomial(n, k)
    end
    return P
end


function calculate_entropy(probas)
    indices_zero = iszero.(probas)
    sum(map(p -> -p * log(p), probas[.!indices_zero])) + sum(indices_zero)
end
