function load_train_data(filenames, folder)

    xs = []
    ys = []

    for filename in filenames

        filename_full = joinpath(folder, filename)

        df = CSV.read(filename_full, DataFrame)
    
        X = df[:, [:x, :y, :z]] |> Matrix{Float32}
        Y = df[:, [:class]] |> Matrix{Float32}
    
        X = diff(X, dims=1)
        Y = Y[1: end-1, :]
    
        # trim 
        L = floor(size(X, 1), base=8 * 10, digits=-1) |> Int
        X = X[1:L, :]
        Y = Y[1:L, :]
    
        X = reshape(X, size(X)..., 1)
        Y = reshape(Y, size(Y)..., 1)
        
        push!(xs, X)
        push!(ys, Y)
    
        push!(xs, reverse(X, dims=1))
        push!(ys, reverse(Y, dims=1))
    
    end

    xs, ys

end
