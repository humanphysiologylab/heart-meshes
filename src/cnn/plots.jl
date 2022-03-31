using UnicodePlots, PlotlyJS

traces = []

for column in (:x, :y, :z)
    # trace = scatter(;y = df_part[:, column])
    y = df_part[:, column] |> diff
    # y = df_real[:, column] |> diff
    trace = scatter(;y = y)
    push!(traces, trace)
end

plot([traces...])
