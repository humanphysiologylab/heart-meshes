using Flux, Flux.Optimise
using Flux: params, ADAM, Momentum, update!
using Flux.Losses: logitbinarycrossentropy, label_smoothing

using BSON: @save, @load

include("../../utils/accuracy.jl")
include("create_model.jl")
include("predict_proba.jl")

##

x, y = first(train_loader)

n_stack = 3
window_size = 128
conv_filter = (7,)
inner_channels = 16
model = create_model(window_size, n_stack; conv_filter)

logitbinarycrossentropy(model(x), y)

w = mean(Y_test .> 0.5)

using Zygote

function loss(x, y; w=w)

    # W = zeros(size(y))
    # Zygote.ignore() do
    #     mask = y .> 0.5
    #     W[mask] .= 1 / w
    #     W[mask] .= 1 / (1 - w)
    # end
  
    logitbinarycrossentropy(
        model(x), y,
        # agg = z -> mean(W .* z)
    )

end

y_pred = model(X_test) .|> σ
@show accuracy(y_pred .> 0.5, Y_test .> 0.5)

loss(x, y)
opt = ADAM()
# opt = Momentum(0.01)

##

best_score = 0
filename_model_save = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/flux-models/model-v2-$n_stack-latest.bson"

##

epochs = 20

for epoch in 1:epochs

    @show epoch

  for d in train_loader
    gs = gradient(params(model)) do
      l = loss(d...)
    end
    Flux.update!(opt, params(model), gs)
  end

  @show loss(X_test, Y_test)
  y_pred = model(X_test) .|> σ
  @show score = accuracy(y_pred .> 0.5, Y_test .> 0.5)

  if score > best_score
    @info "saved"
    @save filename_model_save model
    best_score = score
  end

end

##

@load filename_model_save model

##

folder_save = "/Users/andrey/Work/HPL/projects/Rheeda/tmp"
write(joinpath(folder_save, "X_test.float32"), X_test)
y_pred = model(X_test) .|> σ
write(joinpath(folder_save, "y_pred.float32"), y_pred)

##

using DataFrames, CSV

filename = readdir(folder_dataset, join=true)[52]
df = CSV.read(filename, DataFrame)[1:10:end, :]

filename = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/tmp/times/S10/trajectories/2-rotor.csv"

lineplot(df.x)

##

pred = predict_proba(df, model; window_size)

plt = scatterplot(pred)

t = 1: size(df, 1)
plt = scatterplot(t, df[!, :x])
scatterplot!(plt, t[pred .> 0.5], df[pred .> 0.5, :x])
