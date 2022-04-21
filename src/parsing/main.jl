using DataFrames, CSV

include("read_dat.jl")
include("compress_activation_times.jl")

##

n_points_dict = Dict(
    13 => Int32(1958268),
    15 => Int32(2432365)
)

##

heart = 15
group = 4

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

n_stim = 40
rows = []
append!(rows, fill(nothing, n_stim))

Threads.@threads for i_stim in 1: n_stim

    stim = string(i_stim - 1, pad = 2)
    progress = .!isnothing.(rows) |> sum
    msg = "$(Threads.threadid()) : $stim : $progress/$n_stim"
    println(msg)

    filename_input = joinpath(
        folder_rheeda,
        "tars",
        "G$(group)_M$heart/S$stim",
        "vm_act-thresh.dat"
    )

    subfolder_write = joinpath("M$heart", "G$group", "S$stim")
    folder_write = joinpath(folder_rheeda, "activation-times", subfolder_write)
    filename_starts = joinpath(folder_write, "starts.int32")
    filename_times = joinpath(folder_write, "times.float32")

    # isfile(filename_starts) && continue
    # isfile(filename_times) && continue

    vs, times = read_dat(filename_input)
    starts, times, n_points_found = compress_activation_times(vs, times, n_points_dict[heart])

    # @show length(starts)

    mkpath(folder_write)
    write(filename_starts, starts)
    write(filename_times, times)

    row = Dict(
        :t_max => findmax(times)[1],
        :n_points_found => n_points_found,
        :heart => heart,
        :group => group,
        :stim => stim
    )
    rows[i_stim] = row

end

##

df = DataFrame(rows)
filename_csv = joinpath(folder_rheeda, "activation-times", "M$heart-G$(group).csv")
CSV.write(filename_csv, df)

##
