

# ps = params(
#     model.layers[2].layers...,
#     model.layers[3]
# )

##
X = rand(Float32, 256, 3, 5)

n_hidden = 3
model = WCNN(wt, 3 => 32, n_hidden)
model(X)

ps = params(model.layers...)

grads = gradient(ps) do 
    sum(model(X))
end

Y = model(X) .+ 1.

opt = ADAM()
Flux.train!(
    (x, y) -> mean((model(x) .- y).^2),
    ps,
    zip((X,), (Y,)),
    opt
)

##


##

t = range(0, 2π, length=256 * 3)
period = π
ω = 2π / period
x = sin.(ω * t)
x .+= randn(size(x))

lineplot(t, x)

n = maxtransformlevels(x)

wt = wavelet(WT.db1)
y = dwt(x, wt, 3)

lineplot(t, y)

##

As, Ds = filter_bank(x, wt)

i = 3
D = Ds[i]
A = As[i]
ty = range(0, 2π, length=length(D))
plt = scatterplot(ty, A)
scatterplot!(plt, ty, D)
