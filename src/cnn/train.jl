using Flux, Flux.Optimise
using ProgressMeter
include("model.jl")
include("evaluate.jl")
include("plot_history.jl")

folder_model = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/flux-models/"
filename_model = joinpath(folder_model, "model-latest.bson")

opt = ADAM(1e-4)
α_smooth = 1e-6  # 0.1f0

score_best = 0.
history = []
# let
#     row = Dict{Symbol, Any}(:epoch => 0)
#     row[:loss_train], row[:score_train] = evaluate(model, train_loader; α_smooth=α_smooth)
#     row[:loss_test], row[:score_test] = evaluate(model, test_loader; α_smooth=α_smooth)
#     push!(history, row)
# end

@showprogress for epoch in 1: 100

    row = Dict{Symbol, Any}(:epoch => epoch)

    for (x, y) in train_loader
        grads = gradient(params(model)) do
            ŷ = model(x)

            y_smooth = (α_smooth ≈ 0) ? y : label_smoothing(y, α_smooth, dims=0)
            logitbinarycrossentropy(ŷ, y_smooth)

            # Flux.binary_focal_loss(ŷ .|> σ, y_smooth)

        end
        Optimise.update!(opt, params(model), grads)
    end

    # EVALUATE

    # TRAIN
    row[:loss_train], row[:score_train] = evaluate(model, train_loader; α_smooth=α_smooth)

    # TEST
    row[:loss_test], row[:score_test] = evaluate(model, test_loader; α_smooth=α_smooth)

    if row[:score_test] > score_best
        @save filename_model model
    end

    push!(history, row)

end

history = DataFrame(history)

plot_history(history) |> println
plot_history(history, "score") |> println
