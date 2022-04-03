function ema(x::AbstractVector, α)

    n = length(x)
    result = zeros(n)
    result[1] = x[1]

    for i in 2: n
        result[i] = α * x[i] + (1 - α) * result[i - 1]
    end

    result

end


function ema(M::AbstractMatrix, α)

    n = size(M, 1)
    result = zeros(size(M))
    result[1, :] = M[1, :]

    for i in 2: n
        result[i, :] = α * M[i, :] + (1 - α) * result[i - 1, :]
    end

    result

end
