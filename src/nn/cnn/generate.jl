using DataFrames, CSV

include("ema.jl")
include("rotations.jl")
include("walks.jl")
include("rotors.jl")
include("normalize_path.jl")

##

function generate_trajectory(n_pairs = 3)

    α_global = 0.01

    n_walk_min, n_walk_max = 200, 2000
    # scale_walk_min, scale_walk_max = 10, 100
    α_walk = 5e-3

    n_periods_min, n_periods_max = 1.5, 10
    # scale_rotor_min, scale_rotor_max = 0.5, 2.
    period_min, period_max = 150, 800

    xs = []
    is_rotor = []

    for _ in 1: n_pairs

        n_walk = rand(n_walk_min: n_walk_max)
        # scale_walk = rand(scale_walk_min: scale_walk_max) 

        x_walk = generate_smooth_walk_3d(n_walk, α_walk)
        x_walk = normalize_path(x_walk)
        # x_walk ./= scale_walk

        if !isempty(xs)
            x_walk = align_segments(last(xs), x_walk)
        else
            x_walk .+= rand(3)'
        end

        push!(xs, x_walk)
        push!(is_rotor, zeros(Int, size(x_walk, 1)))

        n_periods = n_periods_min .+ (n_periods_max - n_periods_min) * rand()
        period = rand(period_min: period_max)
        n_rotor = trunc(Int, n_periods * period)
        x_rotor = generate_rotor(n_rotor, period)
        # scale_rotor = scale_rotor_min .+ (scale_rotor_max - scale_rotor_min) * rand()
        # x_rotor .*= scale_rotor
        x_rotor = normalize_path(x_rotor)
        x_rotor = align_segments(x_walk, x_rotor)

        push!(xs, x_rotor)
        
        labels = zeros(Int, size(x_rotor, 1))
        labels[period ÷ 3: end - period ÷ 3] .= 1
        push!(is_rotor, labels)

    end

    x = ema(
        vcat(xs...),
        α_global
    )
    y = vcat(is_rotor...)

    x, y

end

##

x, y = generate_trajectory(1000);
# x .+= randn(size(x))

df = DataFrame(
    x=x[:, 1],
    y=x[:, 2],
    z=x[:, 3],
    class=y
)

##

filename_save = folder_save = "/Users/andrey/Work/HPL/data/rotors-synthetic-latest.csv"
CSV.write(filename_save, df[1:10:end, :])

##

##

using UnicodePlots
using PlotlyJS

x, y = generate_trajectory()

step = 10
x = x[1:step:end, :]
y = y[1:step:end]

trace = scatter3d(;
    x = x[:, 1],
    y = x[:, 2],
    z = x[:, 3],
    mode = "lines",
    line_color = y .|> float,
    marker_size = 1.
)
plot(trace)

##

h = norm.(eachrow(diff(x, dims=1)))
plot(scatter(;y=h))

##

traces = []

for i in 1: 3
    y = x[:, i]
    trace = scatter(;
        y = y,
        mode = "lines"
    )
    push!(traces, trace)
end

plot([traces...])

##

N = 100

folder_save = "/Users/andrey/Work/HPL/data/rotors-synthetic"

for i in 1: N

    x, y = generate_trajectory()

    df = DataFrame(
        x=x[:, 1],
        y=x[:, 2],
        z=x[:, 3],
        class=y
    )

    tag = string(i, pad = 3)
    filename_save = joinpath(
        folder_save,
        "$tag.csv"
    )
    CSV.write(filename_save, df)
end


##
