using DataFrames, CSV
using ProgressMeter

using Flux, Flux.Optimise
using Flux: logitbinarycrossentropy, @epochs, DataLoader, normalise

include("reshape_batch.jl")
include("split_train_test.jl")

include("model.jl")
include("loss.jl")
include("accuracy.jl")
include("plot_history.jl")
include("evaluate.jl")

##

include("validation.jl")

##

filename_save = "/Users/andrey/Work/HPL/data/rotors-synthetic-latest.csv"
df = CSV.read(filename_save, DataFrame)

X = df[:, [:x, :y, :z]] |> Matrix{Float32}
Y = df[:, [:class]] |> Matrix{Float32}

X = diff(X, dims=1)
Y = Y[1: end-1, :]

X = reshape(X, size(X)..., 1)
Y = reshape(Y, size(Y)..., 1)

X = reshape_batch(X)
Y = reshape_batch(Y)

# X = normalise(X)
X .+= 0.25 * randn(size(X))

X_train, X_test, Y_train, Y_test = split_train_test(X, Y)

train_loader = DataLoader((X_train, Y_train), batchsize=16, shuffle=true)
test_loader = DataLoader((X_test, Y_test))

x, y = first(train_loader)

evaluate(model_conv, train_loader)

##

opt = ADAM(1e-3)
α_smooth = 0.1f0

history = []
row = Dict{Symbol, Any}(:epoch => 0)
row[:loss_train], row[:score_train] = evaluate(model_conv, train_loader; α_smooth=α_smooth)
row[:loss_test], row[:score_test] = evaluate(model_conv, test_loader; α_smooth=α_smooth)
row[:loss_val], row[:score_val] = evaluate(model_conv, val_loader; α_smooth=α_smooth)
push!(history, row)

@showprogress for epoch in 1: 10

    row = Dict{Symbol, Any}(:epoch => epoch)

    for (x, y) in val_loader # train_loader
        grads = gradient(params(model_conv)) do
            loss(x, y; α=α_smooth)
        end
        Optimise.update!(opt, params(model_conv), grads)
    end

    # EVALUATE

    # TRAIN
    row[:loss_train], row[:score_train] = evaluate(model_conv, train_loader; α_smooth=α_smooth)

    # TEST
    row[:loss_test], row[:score_test] = evaluate(model_conv, test_loader; α_smooth=α_smooth)

    # VALIDATION
    row[:loss_val], row[:score_val] = evaluate(model_conv, val_loader; α_smooth=α_smooth)

    push!(history, row)

end

history = DataFrame(history)

plot_history(history)
plot_history(history, "score")

##

@epochs 100 train!(loss, params(model_conv), val_loader, opt)


##

using UnicodePlots

y_pred = model_conv(X_test) .|> σ
plt = lineplot(Y_test[1:1000]);
lineplot!(plt, y_pred[1:1000])

##

df_pred = DataFrame(
    x = X_test[:, 1, :][:],
    y = X_test[:, 2, :][:],
    z = X_test[:, 3, :][:],
    class = y_pred[:],
)

filename_pred = "../../pred.csv"
CSV.write(filename_pred, df_pred)

##

folder = "/Volumes/samsung-T5/HPL/Rheeda/rotors/trajectories_interp/"
# filename_real = joinpath(folder, "M13-G3-S13-1.csv")
# filename_real = joinpath(folder, "M13-G1-S10-1.csv")
filename_real = joinpath(folder, "M15-G3-S36-2.csv")

df_real = CSV.read(filename_real, DataFrame)

x = df_real[1:10:end, [:x, :y, :z]] |> Matrix{Float32}
x = diff(x, dims=1)
x = x[1:end-1, :]
x = normalise(x, dims=1)
x = reshape(x, size(x)..., 1)

y_pred = model_conv(x) .|> σ
df_pred = DataFrame(
    x = x[1:length(y_pred), 1, :][:],
    y = x[1:length(y_pred), 2, :][:],
    z = x[1:length(y_pred), 3, :][:],
    class = y_pred[:]
)

filename_pred = "../../pred_real.csv"
CSV.write(filename_pred, df_pred)

##

folder = "/Volumes/samsung-T5/HPL/Rheeda/rotors/trajectories_interp/"
folder_save = "/Users/andrey/Work/HPL/data/rotors-predict-v2"

@showprogress for filename in readdir(folder)

    filename_full = joinpath(folder, filename)
    df = CSV.read(filename_full, DataFrame)

    x = df[:, [:x, :y, :z]] |> Matrix{Float32}
    x = diff(x, dims=1)
    x = x[1:end-1, :]
    x = reshape(x, size(x)..., 1)

    y_pred = model(x) .|> σ
    y_pred = y_pred[:]

    df = df[1:length(y_pred), :]

    df[:, :class] = y_pred

    filename_pred = joinpath(folder_save, filename)
    CSV.write(filename_pred, df)

end
