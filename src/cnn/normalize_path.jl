using LinearAlgebra: norm


function normalize_path(x)  
    h = norm.(eachrow(diff(x, dims=1)))
    S = sum(h) / length(h)
    x ./ S
end
