using Flux
using Flux: normalise


function create_model(
    L_input = 256,
    n_stack = 3;
    input_channels = 3,
    conv_filter = (5,),
    inner_channels = 16,
)

    stacks = []

    for i in 1: n_stack

        in = (i == 1) ? input_channels : inner_channels
        out = inner_channels

        stack = Chain(
            Conv(conv_filter, in=>out, pad=SamePad()),
            BatchNorm(out, relu),
            MaxPool((2,)),
        )

        push!(stacks, stack)

    end

    head = Chain(stacks...)

    x = rand(Float32, L_input, input_channels, 1)

    L, C, N = head(x) |> size
    @assert (C, N) == (inner_channels, 1)

    n_downsampling = 2 ^ n_stack
    @assert L == L_input ÷ n_downsampling

    tail = Chain(
        Flux.flatten,
        Dense(L * inner_channels => L * inner_channels, relu),
        Dense(L * inner_channels => L),
    )

    model = Chain(
        x -> Flux.normalise(x, dims=1),
        head,
        tail,
        Upsample(scale=(n_downsampling,))
    )

end
