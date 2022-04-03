using UnicodePlots


function plot_history(history, key="loss"; yscale=:identity)

    names = "train", "test" # "val"
    keys = ["$(key)_$(name)" for name in names]

    values = history[:, keys] |> Array
    min_loss = minimum(values)
    max_loss = maximum(values)
    ylim = min_loss, max_loss

    plt = lineplot(values[:, 1], name=keys[1]; yscale, ylim)

    for key in Iterators.drop(keys, 1)
        lineplot!(plt, history[:, key], name=key)
    end

    plt

end
