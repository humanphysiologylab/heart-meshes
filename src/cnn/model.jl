model_conv = Chain(
    
    Conv((9,), 3 => 3; dilation=2, pad=SamePad()),
    BatchNorm(3, relu),
    
    Conv((9,), 3 => 3; dilation=2, pad=SamePad()),
    BatchNorm(3, relu),

    MaxPool((2,)),

    Conv((9,), 3 => 3; pad=SamePad()),
    BatchNorm(3, relu),

    Conv((9,), 3 => 3; pad=SamePad()),
    BatchNorm(3, relu),

    MaxPool((2,)),

    Conv((9,), 3 => 3; pad=SamePad()),
    BatchNorm(3, relu),

    Conv((9,), 3 => 1; pad=SamePad()),
    # BatchNorm(10, relu),

    Upsample(4)  # [MaxPool] * 2
)

# n_pools = [typeof(layer) <: MaxPool for layer in model_conv.layers] |> sum
