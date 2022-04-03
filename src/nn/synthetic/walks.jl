include("ema.jl")


function generate_random_walk(n, x₀ = 0.)
    dx = randn(Float64, n)
    dx[1] = 0
    x = x₀ .+ cumsum(dx)
end


function generate_smooth_walk(n, α)
    random_walk = generate_random_walk(n)
    smooth_walk = ema(random_walk, α)
end


function generate_smooth_walk_3d(n, α)
    hcat([generate_smooth_walk(n, α) for _ in 1: 3]...)
end
