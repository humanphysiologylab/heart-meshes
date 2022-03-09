using LinearAlgebra


function calculate_cv(coords, times)

    # size = (vertices, dims)

    i₀ = 1
    p₀ = coords[i₀, :]
    t₀ = times[i₀]

    dx⃗ = coords[i₀ + 1 : end, :] .- p₀'
    dt⃗ = times[i₀ + 1 : end, :] .- t₀

    h⃗ = norm.(eachrow(dx⃗))
    U = dx⃗ ./ h⃗

    ∇t_proj = dt⃗ ./ h⃗

    ∇t = vec(U \ ∇t_proj)
    cv = ∇t ./ (norm(∇t) ^ 2)

end

##

# t_coords = [
#     0. 0.;
#     1. 0.;
#     0. 1.
# ]

# t_times = [0., 1., 1.]
# t_times = [0., -1., 1.]

# ∇t, cv = calculate_cv(t_coords, t_times)
