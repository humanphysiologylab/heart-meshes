include("read_binary.jl")


function load_arrays(h::Integer, g::Integer, s::Integer; folder_rheeda)

    s_pad = string(s, pad = 2)

    subfolder = "M$h/G$g/S$s_pad"

    folder_activation = joinpath(folder_rheeda, "activation-times")
    folder_conduction = joinpath(folder_rheeda, "conduction")

    filename_starts = joinpath(folder_activation, subfolder, "starts.int32")
    filename_times = joinpath(folder_activation, subfolder, "times.float32")
    filename_conduction = joinpath(folder_conduction, subfolder, "conduction.float32")

    starts = read_binary(filename_starts, Int32)
    times = read_binary(filename_times, Float32)
    conduction = read_binary(filename_conduction, Float32)

    a = ActArray(starts, Dict(:times => times, :conduction => conduction))

end
