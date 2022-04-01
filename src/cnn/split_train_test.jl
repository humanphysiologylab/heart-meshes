using Random

function split_train_test(X::AbstractArray, Y::AbstractArray, test_size::AbstractFloat=0.2; dim=nothing, seed=42)
    X_train, X_test = split_train_test(X, test_size; dim, seed)
    Y_train, Y_test = split_train_test(Y, test_size; dim, seed)
    (; X_train, X_test, Y_train, Y_test)
end


function split_train_test(X::AbstractArray, test_size::AbstractFloat=0.2; dim=nothing, seed=42)
    if isnothing(dim)
        dim = ndims(X)
    end
    n = size(X, dim)
    k = max(1, trunc(Int, n * test_size))

    indices = randperm(MersenneTwister(seed), n)
    indices_test = indices[1: k]
    indices_train = indices[k + 1: end]

    ax = axes(X) .|> collect |> collect

    ax[dim] = indices_test
    X_test = X[ax...]

    ax[dim] = indices_train
    X_train = X[ax...]

    X_train, X_test

end
