using Flux, Flux.Optimise
using Flux.Losses: label_smoothing, logitbinarycrossentropy, binary_focal_loss
using ProgressMeter
using BSON: @save, @load

include("model.jl")
include("evaluate.jl")
include("../utils/plot_history.jl")

folder_model = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/flux-models/"
filename_model = joinpath(folder_model, "model-wcnn-latest.bson")

η = 1e-3

opt = ADAM(η)
α_smooth = 0. # 1e-6  # 0.1f0

score_best = 0.
history = []

@showprogress for epoch in 1: 10

    row = Dict{Symbol, Any}(:epoch => epoch)

    ps = params(
        model.layers[2].layers...,
        model.layers[3]
    )

    for (x, y) in train_loader
        grads = gradient(ps) do
            ŷ = model(x)

            # y_smooth = (α_smooth ≈ 0) ? y : label_smoothing(y, α_smooth, dims=0)
            # logitbinarycrossentropy(ŷ, y_smooth)

            # y1 = label_smoothing(y, 0.2f0, dims=0)
            binary_focal_loss(σ.(ŷ), y, γ=0, ϵ=1e-6)

        end
        Optimise.update!(opt, ps, grads)
    end

    # EVALUATE

    # TRAIN
    row[:loss_train], row[:score_train] = evaluate(model, train_loader; α_smooth=α_smooth)

    # TEST
    row[:loss_test], row[:score_test] = evaluate(model, test_loader; α_smooth=α_smooth)

    if row[:score_test] > score_best
        @save filename_model model
        global score_best = row[:score_test]
    end

    push!(history, row)
    @show score_best

end

history = DataFrame(history)

plot_history(history) |> println
plot_history(history, "score") |> println

@load filename_model model
@show score_best
