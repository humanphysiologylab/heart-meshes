using Flux: label_smoothing, logitbinarycrossentropy
include("accuracy.jl")


function evaluate(model, data_loader; α_smooth=1e-6)

    acc_num = 0.
    acc_denom = 0.
    loss = 0.
    n = 0

    for (x, y) in data_loader
        ŷ = model(x)
        y_smooth = label_smoothing(y, α_smooth, dims=0)
        loss += logitbinarycrossentropy(ŷ, y_smooth; agg=sum)
        n += length(ŷ)
        num, denom = accuracy_part(ŷ .> 0.5, y .> 0.5)
        acc_num += num
        acc_denom += denom
    end

    loss /= n
    score = acc_num / acc_denom

    (; loss, score)

end
