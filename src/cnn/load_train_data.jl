function load_train_data_zip(filenames, folder)

    xs = []
    ys = []

    for filename in filenames

        filename_full = joinpath(folder, filename)

        df = CSV.read(filename_full, DataFrame)
    
        X = df[:, [:x, :y, :z]] |> Matrix{Float32}
        Y = df[:, [:class]] |> Matrix{Float32}
        # Y = 1 .- Y
    
        X = diff(X, dims=1)
        Y = Y[1: end-1, :]
    
        # trim 
        L = floor(size(X, 1), base=320, digits=-1) |> Int
        X = X[1:L, :]
        Y = Y[1:L, :]
    
        X = reshape(X, size(X)..., 1)
        Y = reshape(Y, size(Y)..., 1)
        
        push!(xs, X)
        push!(ys, Y)
    
        push!(xs, reverse(X, dims=1))
        push!(ys, reverse(Y, dims=1))

        push!(xs, -X)
        push!(ys, Y)


        # TODO: flip axes

    end

    xs, ys

end


function load_train_data(filenames, folder; L::Integer, step::Integer)

    xs = []
    ys = []

    for filename in filenames

        filename_full = joinpath(folder, filename)

        df = CSV.read(filename_full, DataFrame)

        i_starts = [
            (1: step: size(df, 1) - L)...,
            (size(df, 1) - L : -step: 1)...
        ]
        for i_start in i_starts

            i_end = i_start + L
                    
            X = df[i_start: i_end, [:x, :y, :z]] |> Matrix{Float32}
            Y = df[i_start: i_end, [:class]] |> Matrix{Float32}
            # Y = 1 .- Y
        
            X = diff(X, dims=1)
            Y = Y[1: end-1, :]
        
            # trim 
            # L = floor(size(X, 1), base=16 * 10, digits=-1) |> Int
            # X = X[1:L, :]
            # Y = Y[1:L, :]                                       
        
            X = reshape(X, size(X)..., 1)
            Y = reshape(Y, size(Y)..., 1)
            
            push!(xs, X)
            push!(ys, Y)
        
            push!(xs, reverse(X, dims=1))
            push!(ys, reverse(Y, dims=1))

            push!(xs, -X)
            push!(ys, Y)

        end

            # TODO: flip axes

    end

    x = first(xs)
    y = first(ys)
    X = similar(x, size(x, 1), size(x, 2), length(xs))
    Y = similar(y, size(y, 1), size(y, 2), length(ys))

    for (i, (x, y)) in enumerate(zip(xs, ys))
        X[:, :, i] = x
        Y[:, :, i] = y
    end

    X, Y

end
