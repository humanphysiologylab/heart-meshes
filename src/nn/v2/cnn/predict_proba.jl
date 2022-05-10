function predict_proba(df, model; window_size=128)

    xyz = [:x, :y, :z]

    result = fill(NaN32, size(df, 1))

    for i in 1: window_size: size(df, 1) - window_size

        df_slice = df[i: i + window_size - 1, :]
        x = Array{Float32}(df_slice[:, xyz])

        L, C = size(x)

        x = reshape(x, (L, C, 1))

        pred = model(x) .|> σ
        result[i: i + window_size - 1] .= pred

    end

    df_slice = df[end - window_size : end, :]
    x = Array{Float32}(df_slice[:, xyz])
    L, C = size(x)
    x = reshape(x, (L, C, 1))
    pred = model(x) .|> σ
    result[end - window_size: end] .= pred

    result

end
