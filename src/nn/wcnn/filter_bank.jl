using Wavelets
using Zygote


function filter_bank(x::AbstractVector, wt, n=maxtransformlevels(x))

    As = []
    Ds = []

    A = x
    
    for _ in 1: n
        k = length(A) ÷ 2
        AD = dwt(A, wt, 1)
        A, D = AD[1: k], AD[k + 1: end]
        push!(As, A)
        push!(Ds, D)

    end

    return As, Ds

end


function dwt_split(X::AbstractArray, wt)

    L, C, B = size(X)

    L % 2 ≠ 0 && error("L is odd: $L")
    L_out = L ÷ 2

    # A = Zygote.Buffer(X, L_out, C, B)
    # D = Zygote.Buffer(X, L_out, C, B) 
    A = zeros(Float32, L_out, C, B)
    D = zeros(Float32, L_out, C, B)

    for ic in 1: C, ib in 1: B
        Zygote.ignore() do
            x = dwt(X[:, ic, ib], wt, 1)
            A[:, ic, ib] = x[1: L_out]
            D[:, ic, ib] = x[L_out + 1: L]
        end
    end

    # Zygote.copy(A), Zygote.copy(D)
    A, D

end
