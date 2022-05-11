using Flux, Flux.Optimise
using Flux: params, ADAM, Momentum, update!
using Flux.Losses: logitbinarycrossentropy

using BSON: @save, @load

include("../../utils/accuracy.jl")
include("create_model.jl")
include("predict_proba.jl")

##

x, y = first(train_loader)

# model = create_model(128)
logitbinarycrossentropy(model(x), y)
loss(x, y) = logitbinarycrossentropy(model(x), y)

y_pred = model(X_test) .|> σ
@show accuracy(y_pred .> 0.5, Y_test .> 0.5)

loss(x, y)
# opt = ADAM()
opt = Momentum(0.01)

##

epochs = 1

for epoch = 1:epochs
  for d in train_loader
    gs = gradient(params(model)) do
      l = loss(d...)
    end
    Flux.update!(opt, params(model), gs)
  end
#   @show accuracy(valX, valY)
  @show loss(X_test, Y_test)
  y_pred = model(X_test) .|> σ
  @show accuracy(y_pred .> 0.5, Y_test .> 0.5)
end

##

folder_save = "/Users/andrey/Work/HPL/projects/Rheeda/tmp"
write(joinpath(folder_save, "X_test.float32"), X_test)
write(joinpath(folder_save, "y_pred.float32"), y_pred)

##

filename_model_save = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/flux-models/model-v2-latest.bson"
@save filename_model_save model

##

@load filename_model_save model

##

using DataFrames, CSV

filename = readdir(folder_dataset, join=true)[79]

filename = "/Users/andrey/Work/HPL/projects/rheeda/heart-meshes/tmp/times/S10/trajectories/1-rotor.csv"

df = CSV.read(filename, DataFrame)
lineplot(df.t, df.x)

##

pred = predict_proba(df, model)

lineplot(pred)
lineplot(df[.!isnan.(pred), :x])
