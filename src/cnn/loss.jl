using Flux: logitbinarycrossentropy
using Flux.Losses: label_smoothing

function loss(x, y; α=0.1f0)
    ŷ = model_conv(x)
    y_smooth = label_smoothing(y, α, dims=0)
    logitbinarycrossentropy(ŷ, y_smooth)
end
