function predict_proba(df, model; window_size=128)

    xyz = [:x, :y, :z]

    proba = fill(NaN32, size(df, 1))

    df_len = size(df, 1)

    if df_len < window_size
        @warn "df is too small: $df_len"
        return proba
    end

    indices_start = 1: window_size: df_len - window_size |> collect
    push!(indices_start, df_len - window_size + 1)

    for i in indices_start

        df_slice = df[i: i + window_size - 1, :]
        x = Array{Float32}(df_slice[:, xyz])

        L, C = size(x)

        x = reshape(x, (L, C, 1))

        y = model(x) .|> σ
        proba[i: i + window_size - 1] .= y

    end

    proba

end
