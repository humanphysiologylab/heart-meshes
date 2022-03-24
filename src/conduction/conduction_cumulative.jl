using ProgressMeter
include("../io/read_binary.jl")
include("../ActArrays/ActArrays.jl")

##

function accumulate_conduction(
    folder_activation::String,
    folder_conduction::String,
    n_points,
    time_stop::AbstractFloat = 2500.0
)

    n_stim = 40

    activation = zeros(Int32, n_points)
    transmission = zeros(Int32, n_points)

    for i_stim in 1: n_stim

        stim = string(i_stim - 1, pad = 2)
        subfolder_stim = "S$stim"

        filename_starts = joinpath(folder_activation, subfolder_stim, "starts.int32")
        filename_times = joinpath(folder_activation, subfolder_stim, "times.float32")
        filename_conduction = joinpath(folder_conduction, subfolder_stim, "conduction.float32")

        starts = read_binary(filename_starts, Int32)
        times = read_binary(filename_times, Float32)
        conduction = read_binary(filename_conduction, Float32)

        a = ActArray(starts, Dict(:times => times, :conduction => conduction))

        n_points_found = length(a.starts)
        if n_points ≠ n_points_found
            @warn "wrong number of points found: $n_points ≠ $n_points_found"
            continue
        end


        time_stop_found = maximum(times)
        if time_stop_found < time_stop 
            @warn "activation ends before time_stop: $time_stop_found < $time_stop"
            continue
        end

        for i in 1: n_points

            t = get_subarray(a, i, :times)
            c = get_subarray(a, i, :conduction)

            n_act = searchsortedlast(t, time_stop)
            n_trans = sum(isone.(c[1:n_act]))

            # @assert n_act >= n_trans

            activation[i] += n_act
            transmission[i] += n_trans

        end

    end

    (;activation, transmission)

end

##

n_points_dict = Dict(
    13 => Int32(1958268),
    15 => Int32(2432365)
)

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda"
folder_write = joinpath(folder_rheeda, "conduction-cumulative")

hearts = (15,)
groups = 2: 4

pairs = Iterators.product(hearts, groups) |> collect

Threads.@threads for (heart, group) in pairs

    subfolder = "M$heart/G$group"

    msg = "$(Threads.threadid()) : $subfolder"
    println(msg)

    folder_activation = joinpath(folder_rheeda, "activation-times", subfolder)
    folder_conduction = joinpath(folder_rheeda, "conduction", subfolder)

    n_points = n_points_dict[heart]
    activation, transmission = accumulate_conduction(folder_activation, folder_conduction, n_points)

    tag = "M$heart-G$group"
    filename_transmission = joinpath(folder_write, "transmission-$tag.int32")
    filename_activation = joinpath(folder_write, "activation-$tag.int32")

    write(filename_transmission, transmission)
    write(filename_activation, activation)

end

##

p = transmission ./ activation

p[isnan.(p)] .= 0

histogram( @. log10(p[!iszero(p)]) )

##
