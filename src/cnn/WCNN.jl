using Flux
include("filter_bank.jl")


struct WCNN
    wt
    layers

    function WCNN(wt, ch::Pair{<:Integer, <:Integer}, n::Integer=1; filter=(3,))

        ch_in = first(ch)  # ex: 3
        ch_out = last(ch)  # ex: 16

        double_ch_in =  2 * ch_in        # ex: 6
        ch_diff = ch_out - double_ch_in  # ex: 10

        stride = 2
        pad = SamePad()

        layers = []

        for i in 0: n

            ch = ch_out => ch_diff
            activation = relu

            if (i == 0)
                ch = double_ch_in => ch_diff
            elseif (i == n)
                activation = identity
                ch = ch_out => ch_out
            end

            layer = Conv(filter, ch, activation; stride, pad)
            push!(layers, layer)

        end

        new(wt, layers)

    end

end

function (model::WCNN)(X)

    wt = model.wt

    # First layer
    first_layer = first(model.layers)
    A, D = dwt_split(X, wt)
    AD = hcat(A, D)
    X = first_layer(AD)
    A, D = dwt_split(A, wt)

    # Hidden layers
    hidden_layers = Iterators.drop(model.layers, 1)
    n_hidden = length(hidden_layers)
    for (i, layer) in enumerate(hidden_layers)
        ADX = hcat(A, D, X)
        X = layer(ADX)

        i == n_hidden && break
        A, D = dwt_split(A, wt)
    end

    return X
    
end
