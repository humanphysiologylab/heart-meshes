using DataFrames, CSV

include("read_dat.jl")
include("compress_activation_times.jl")

##

n_points_dict = Dict(
    13 => Int32(1958268),
    15 => Int32(2432365)
)

##

heart = 13
group = 2

folder_rheeda = "/media/andrey/samsung-T5/HPL/Rheeda/"

rows = []

Threads.@threads for i_stim in 0: 39

    stim = string(i_stim, pad = 2)
    msg = "$(Threads.threadid()) : $stim"
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

    isfile(filename_starts) && continue
    isfile(filename_times) && continue

    vs, times = read_dat(filename_input)
    starts, times, n_points_found = compress_activation_times(vs, times, n_points_dict[heart])

    mkpath(folder_write)
    write(filename_starts, starts)
    write(filename_times, times)

    row = Dict(
        :t_max => findmax(times)[1],
        :n_points_found => n_points_found,
        :heart => heart,
        :group => group,
        :stim => i_stim
    )
    push!(rows, row)

end

##

df = DataFrame(rows)
filename_csv = joinpath(folder_rheeda, "activation-times", "M$heart-G$(group).csv")
CSV.write(filename_csv, df)
