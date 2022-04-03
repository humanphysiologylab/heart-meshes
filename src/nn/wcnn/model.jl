using Wavelets
using Flux
include("WCNN.jl")

wt = wavelet(WT.db5)

n_downsampling = 10

preprocessor = Chain(
    MeanPool((n_downsampling,)),
    x -> Flux.normalise(x, dims=1)
)

model = Chain(
    preprocessor,
    WCNN(wt, 3 => 64, 2; filter=(7,)),
    Conv((1,), 64 => 1; pad=SamePad()),
    Upsample(n_downsampling * 2^4)
)
