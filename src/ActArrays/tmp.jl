include("../io/read_binary.jl")
include("../ActArrays/ActArrays.jl")

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

heart = 13
group = 3
stim = 13

subfolder = joinpath("M$heart", "G$group", "S$stim")

folder_activation = joinpath(folder_rheeda, "activation-times", subfolder)
filename_starts = joinpath(folder_activation, "starts.int32")
filename_times = joinpath(folder_activation, "times.float32")

folder_conduction = joinpath(folder_rheeda, "conduction", subfolder)
filename_conduction = joinpath(folder_conduction, "conduction.float32")

starts = read_binary(filename_starts, Int32)
times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)

a = ActArray(starts, Dict(:times => times, :conduction => conduction))
