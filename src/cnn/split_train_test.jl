function split_train_test(X, Y, test_size=0.2)
    k = trunc(Int, size(X, ndims(X)) * (1 - test_size))
    X_train, X_test = X[:, :, 1: k], X[:, :, k: end]
    Y_train, Y_test = Y[:, :, 1: k], Y[:, :, k: end]
    (; X_train, X_test, Y_train, Y_test)
end
