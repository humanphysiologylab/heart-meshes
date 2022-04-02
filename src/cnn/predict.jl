folder = "/Users/andrey/Work/HPL/data/rotors-predict"
folder_save = "/Users/andrey/Work/HPL/data/rotors-predict-v2"

@showprogress for filename in readdir(folder)

    filename_full = joinpath(folder, filename)
    df = CSV.read(filename_full, DataFrame)

    x = df[:, [:x, :y, :z]] |> Matrix{Float32}
    x = diff(x, dims=1)

    L = floor(size(x, 1), base=320, digits=-1) |> Int
    x = x[1:L, :]

    x = reshape(x, size(x)..., 1)

    y_pred = model(x) .|> σ
    y_pred = y_pred[:]

    df = df[1:length(y_pred), :]

    df[:, :class] = y_pred

    filename_pred = joinpath(folder_save, filename)
    CSV.write(filename_pred, df)

end
