include("../io/read_binary.jl")
include("../io/load_adj_matrix.jl")
include("calculate_conduction_map.jl")

##

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda/"

heart = 15

folder_adj_matrix = joinpath(folder_rheeda, "geometry", "M$heart", "adj-vertices")
A = load_adj_matrix(folder_adj_matrix, false)

##

cv_min = 10.  # 10 um/s = 1 cm/s

for group in 1: 4

    println("Group: ", group)

    Threads.@threads for i_stim in 0: 39

        stim = string(i_stim, pad = 2)
        msg = "$(Threads.threadid()) : $stim"
        println(msg)

        subfolder = joinpath("M$heart", "G$group", "S$stim")

        folder_activation = joinpath(folder_rheeda, "activation-times", subfolder)
        filename_starts = joinpath(folder_activation, "starts.int32")
        filename_times = joinpath(folder_activation, "times.float32")

        folder_conduction = joinpath(folder_rheeda, "conduction", subfolder)
        filename_conduction = joinpath(folder_conduction, "conduction.float32")

        isfile(filename_conduction) && continue

        starts = read_binary(filename_starts, Int32)
        times = read_binary(filename_times, Float32)

        conduction = calculate_conduction_map(A, times, starts; cv_min)
        mkpath(folder_conduction)
        write(filename_conduction, conduction)

    end

end

##

# mask_nan = .!isnan.(conduction)
# mask_zero = .!iszero.(conduction)
# histogram(log10.(conduction[mask_nan .& mask_zero]))
# histogram(conduction[mask_nan .& mask_zero])

# mean(conduction[.!isnan.(conduction)])

    # break

# end
