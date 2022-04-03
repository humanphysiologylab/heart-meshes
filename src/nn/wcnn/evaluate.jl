using Flux: label_smoothing, logitbinarycrossentropy, binary_focal_loss
include("../utils/accuracy.jl")


function evaluate(model, data_loader; α_smooth=0.)

    acc_num = 0.
    acc_denom = 0.
    loss = 0.
    n = 0

    for (x, y) in data_loader
        ŷ = model(x)
        
        y_smooth = (α_smooth ≈ 0) ? y : label_smoothing(y, α_smooth, dims=0)
        loss += logitbinarycrossentropy(ŷ, y_smooth; agg=sum)
        
        # loss += binary_focal_loss(σ.(ŷ), y, ϵ=1e-6)

        n += length(ŷ)
        num, denom = accuracy_part(ŷ .> 0.5, y .> 0.5)
        acc_num += num
        acc_denom += denom
    end

    loss /= n
    score = acc_num / acc_denom

    (; loss, score)

end
