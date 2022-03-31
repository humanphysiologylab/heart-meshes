using Flux: tanh


function generate_rotor(
    n,
    period;
    asymmetry_ratio = 0.75,
    tanh_shift_amplitude = 2.,
    asynchrony_ratio = 0.01
)

    t = 0: n - 1
    asynchrony = (1 .- asynchrony_ratio .+ 2 * asynchrony_ratio * rand(3))

    # p = full(period, n)
    # p .*= (0.95 + 0.1 * rand()) * 2π / (period * rand(3: 10)) .* t |> sin

    acceleration_magnitude = 0.1
    acceleration = acceleration_magnitude .* exp.(-t / period)

    ω = 2π / period .* asynchrony
    Φ = rand(3) * 2π
    Z = (rand(3) .- 0.5) * tanh_shift_amplitude

    scale = (1 - asymmetry_ratio) .+ asymmetry_ratio * rand(3)

    t_acc = @. t * (1. + acceleration)

    x = @. scale' * tanh(sin(ω' * t_acc + Φ') - Z')

    # modulation_period = period * (1 + 3 * rand())
    # ω_modulation = 2π / modulation_period
    # Φ_modulation = rand(3) * 2π
    # modulation_amp = 0. #  0.5 * rand()
    # modulation = @. 1. + modulation_amp .* sin(ω_modulation * t + Φ_modulation')

    # x = x .* modulation

end
