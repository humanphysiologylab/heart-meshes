using Flux

inner_channels = 10
conv_filter = (13,)
pool_window = (2,)

n_downsampling = 10

preprocessor = Chain(
    MeanPool((n_downsampling,)),
    x -> Flux.normalise(x, dims=1)
)

model = Chain(

    preprocessor,

    Conv(conv_filter, 3 => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),
    
    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => 1; pad=SamePad()),

    Upsample(n_downsampling * pool_window[1]^3)
)
