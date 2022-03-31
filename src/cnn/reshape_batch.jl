function reshape_batch(X, sample_size=256)
    n_full = size(X, 1) ÷ sample_size
    X = X[1: n_full * sample_size, :, :]
    X = reshape(X, sample_size, n_full, :)
    X = permutedims(X, (1, 3, 2))
end
