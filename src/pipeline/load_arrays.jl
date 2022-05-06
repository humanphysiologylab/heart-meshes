include("../io/read_binary.jl")
include("../ActArrays/ActArrays.jl")

function load_arrays(folder_times)

    filename_starts = joinpath(folder_times, "starts.int32")
    filename_times = joinpath(folder_times, "times.float32")
    filename_conduction = joinpath(folder_times, "conduction.float32")

    starts = read_binary(filename_starts, Int32)
    times = read_binary(filename_times, Float32)
    conduction = read_binary(filename_conduction, Float32)

    a = ActArray(starts, Dict(:times => times, :conduction => conduction))

end
