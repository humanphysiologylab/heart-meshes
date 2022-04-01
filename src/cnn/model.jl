inner_channels = 10
conv_filter = (9,)
pool_window = (2,)

model_conv = Chain(

    x -> normalise(x, dims=1),
    
    Conv(conv_filter, 3 => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),
    
    Conv(conv_filter, inner_channels => inner_channels; dilation=2, pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    MaxPool(pool_window),

    Conv(conv_filter, inner_channels => inner_channels; pad=SamePad()),
    BatchNorm(inner_channels, relu),

    Conv(conv_filter, inner_channels => 1; pad=SamePad()),
    # BatchNorm(10, relu),

    Upsample(4)  # [MaxPool] * 2
)

# n_pools = [typeof(layer) <: MaxPool for layer in model_conv.layers] |> sum
