using Flux

inner_channels = 10
conv_filter = (11,)
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

    # Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    # BatchNorm(inner_channels, relu),

    # Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    # BatchNorm(inner_channels, relu),

    # MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => 1; pad=SamePad()),

    Upsample(n_downsampling * pool_window[1]^2)
)

##

struct SkipBlock(x)

    y = Conv(conv_filter, 3 => inner_channels; pad=SamePad())(x)
    y = BatchNorm(inner_channels, relu)(y)
    
    y = Conv(conv_filter, inner_channels => inner_channels; pad=SamePad())(y)
    y = BatchNorm(inner_channels, relu)(y)

    y = MaxPool(pool_window)(y)

    x = MaxPool(pool_window)(x)

    cat(x, y, dims=ndims(x) - 1)
    
end

skip_block = Chain(
    Conv(conv_filter, 3 => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),
    
    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window)
)

model = Chain(

    preprocessor,

    x -> cat(
        MaxPool(pool_window)(x),
        skip_block(x),
        dims=ndims(x) - 1
    ),

    # Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    # BatchNorm(inner_channels, relu),

    # Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    # BatchNorm(inner_channels, relu),

    # MaxPool(pool_window),

    Conv(conv_filter, inner_channels + 3 => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => 1; pad=SamePad()),

    Upsample(n_downsampling * pool_window[1]^2)
)
