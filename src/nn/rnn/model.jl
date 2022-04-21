using Flux
using Flux.Losses: logitbinarycrossentropy
using Flux: train!, reset!, @epochs

n_downsampling = 10

preprocessor = Chain(
    MeanPool((n_downsampling,)),
    x -> Flux.normalise(x, dims=1)
)

model_cnn = Chain(
    Conv((3,), 3 => 8, relu; pad=SamePad()),
    MaxPool((2,)),
    Conv((3,), 8 => 16, relu; pad=SamePad()),
    MaxPool((2,))
)

model_rnn = LSTM(16, 32)

model_dense = Chain(
    Dense(32, 16, relu),
    Dense(16, 1)
)


model = Chain(
    preprocessor,
    model_cnn,
    x -> [model_rnn(x) for x in eachslice(x, dims=1)],
    x -> [model_dense(x) for x in x],
    x -> vcat(x...),
    x -> reshape(x, size(x, 1), 1, size(x, 2)),
    Upsample(n_downsampling * 2^2)
)

model = Chain(
    preprocessor,
    model_cnn,
    Conv((3,), 16 => 1; pad=SamePad()),
    Upsample(n_downsampling * 2^2)
)

##

x = rand(Float32, 128, 3, 1)
Flux.reset!(model_rnn)
y = model(x)

##

x, y = first(train_loader)
ŷ = model(x)

function loss(x, y)
    reset!(model_rnn)
    ŷ = model(x)
    logitbinarycrossentropy(ŷ, y)
end

loss(x, y)

##

grads = gradient(params(model)) do
    loss(x, y)
end

opt = ADAM()

first(train_loader)

x, y = first(train_loader)
xy = zip((x,), (y,),)

train!(loss, params(model), xy, opt)

##

train!(loss, params(model), train_loader, opt)


##
