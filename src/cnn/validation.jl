using DataFrames, CSV

folder_validation = "/Users/andrey/Work/HPL/data/rotors-marked-up"

xs = []
ys = []

for filename in readdir(folder_validation, join=true)

    local df = CSV.read(filename, DataFrame)
    df = df[1 : 10 : end, :]

    X = df[:, [:x, :y, :z]] |> Matrix{Float32}
    Y = df[:, [:class]] |> Matrix{Float32}

    X = diff(X, dims=1)
    Y = Y[1: end-1, :]

    n = 8
    L = (size(X, 1) ÷ n) * n
    X = X[1:L, :]
    Y = Y[1:L, :]

    X = reshape(X, size(X)..., 1)
    Y = reshape(Y, size(Y)..., 1)

    # X = normalise(X, dims=1)

    push!(xs, X)
    push!(ys, Y)

    # reverse time
    push!(xs, X[end:-1:1, :, :])
    push!(ys, Y[end:-1:1, :, :])

end

##

val_loader = zip(xs, ys)
