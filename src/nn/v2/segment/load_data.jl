using DataFrames, CSV
using StatsBase


function load_data(
    filenames,
    folder_dataset;

    downsampling_value=10,
    window_size = 256,
    step = window_size ÷ 2
)

    xyz = [:x, :y, :z]

    dfs = DataFrame[]

    for filename in filenames

        filename = joinpath(folder_dataset, filename)
        df = CSV.read(filename, DataFrame)

        df = df[1:downsampling_value:end, :]

        push!(dfs, df)
        
    end

    for (i, df) in enumerate(dfs)

        i == 1 && continue

        x = Vector(df[1, xyz]) - Vector(dfs[i - 1][end, xyz])

        df[:, xyz] .-= x'

    end

    df = vcat(dfs...)

    X = []
    Y = []

    for i in 1: step: size(df, 1) - window_size
    
        # df_slice = df[i: i + window_size, :]
        # v = diff(Array(df_slice[:, xyz]), dims=1)

        df_slice = df[i: i + window_size - 1, :]
        x = Array(df_slice[:, xyz])
        y = Vector(df_slice[:, :class])

        push!(X, x)
        push!(Y, y)

    end

    Y = cat(Y..., dims=2)
    X = cat(X..., dims=3)

    X = cat(X, -X, dims=3)
    Y = cat(Y, Y, dims=2)

    Float32.(X), Float32.(Y)

end
