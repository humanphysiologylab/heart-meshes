using DataFrames, CSV
using ProgressMeter

using Flux, Flux.Optimise
using Flux: logitbinarycrossentropy, @epochs, DataLoader, normalise

include("reshape_batch.jl")
include("split_train_test.jl")

##

include("model.jl")
include("loss.jl")

##

filename_save = "/Users/andrey/Work/HPL/data/rotors-synthetic-latest.csv"
df = CSV.read(filename_save, DataFrame)

##

X = df[:, [:x, :y, :z]] |> Matrix{Float32}
Y = df[:, [:class]] |> Matrix{Float32}

X = diff(X, dims=1)
Y = Y[1: end-1, :]

X = reshape(X, size(X)..., 1)
Y = reshape(Y, size(Y)..., 1)

X = reshape_batch(X)
Y = reshape_batch(Y)

X = normalise(X)
X .+= 0.25 * randn(size(X))

X_train, X_test, Y_train, Y_test = split_train_test(X, Y)

train_loader = DataLoader((X_train, Y_train), batchsize=16, shuffle=true)
# test_loader = DataLoader((X_test, Y_test), batchsize=16, shuffle=true)

x, y = first(train_loader)

loss(x, y)

##

history = []
opt = ADAM(1e-3)

@showprogress for epoch in 1: 100

    row = Dict{Symbol, Any}(:epoch => epoch)

    loss_train_sum = 0.

    for (x, y) in train_loader

        grads = gradient(params(model_conv)) do
            loss_train = loss(x, y)
            loss_train_sum += loss_train
        end

        Optimise.update!(opt, params(model_conv), grads)
    end

    loss_test = loss(X_test, Y_test)
    @show row[:loss_test] = loss_test
    loss_train = loss_train_sum / length(train_loader)
    @show row[:loss_train] = loss_train

    push!(history, row)

end

history = DataFrame(history)

##

plt = lineplot(history.loss_train, color=:blue, yscale=:log10);
scatterplot!(plt, history.loss_test, color=:red)

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
filename_real = joinpath(folder, "M13-G1-S13-1.csv")
# filename_real = joinpath(folder, "M15-G3-S36-2.csv")

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
