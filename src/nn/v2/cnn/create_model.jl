using Flux
using Flux: normalise


function create_model(
    input_L = 256,
    n_stack = 3;
    input_channels = 3,
    conv_filter = (5,),
    inner_channels = 16,
)

    preprocessor = Chain(
        # MeanPool((n_downsampling,)),
        x -> Flux.normalise(x, dims=1)
    )

    stacks = []

    for i in 1: n_stack

        in = (i == 1) ? 3 : inner_channels
        out = inner_channels

        stack = Chain(
            Conv(conv_filter, in => out),
            BatchNorm(out, relu),
            MaxPool((2,)),
        )

        push!(stacks, stack)

    end

    head = Chain(
        preprocessor,
        stacks...
    )

    x = rand(Float32, input_L, input_channels, 1)

    L, C, N = head(x) |> size
    @assert (C, N) == (inner_channels, 1)

    tail = Chain(
        Dense(L * inner_channels => 64, relu),
        Dense(64 => 1),
    )

    model = Chain(
        head,
        # x -> reshape(x, :, size(x, 3)),
        Flux.flatten,
        tail
    )

end
