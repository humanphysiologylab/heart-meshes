function rolling_mean(x, n)
    rs = cumsum(x)[n:end] .- cumsum([0.0; x])[1:end-n]
    return rs ./ n
end
