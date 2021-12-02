include("../../src/read_binary.jl")

i_heart = 13
i_group = 4

folder_group_data = "/media/andrey/easystore/Rheeda/activation/data-light/M$i_heart/G$i_group"
folder_group_results = "/media/andrey/easystore/Rheeda/activation/results/M$i_heart/G$i_group"

##

n_points = nothing
conduction_percent_sum = nothing
conduction_percent_count = nothing

for (root, dirs, files) in walkdir(folder_group_data)

    !isempty(dirs) && continue

    folder_stim = splitpath(root)[end]
    @info "> $folder_stim"

    filename_times = joinpath(root, "times.float32")
    filename_starts = joinpath(root, "indices_start.int32")

    root_results = replace(root, "data-light" => "results")
    filename_conduction = joinpath(root_results, "conduction.float32")

    filenames = filename_starts, filename_times, filename_conduction
    if !all(isfile.(filenames))
        @warn "incomplete root!"
    end

    # times = read_binary(filename_times, Float32)  # useless here
    conduction = read_binary(filename_conduction, Float32)
    n_times = length(conduction)

    starts = read_binary(filename_starts, Int32)
    stops = similar(starts)
    @views stops[1:end-1] = starts[2:end] .- 1
    stops[end] = n_times

    if isnothing(n_points)
        n_points = length(starts)
        conduction_percent_sum = zeros(n_points)
        conduction_percent_count = zeros(Int, n_points)
        @info "n_points = $n_points"
    else
        @assert n_points == length(starts)
    end

    @views for (i_point, (start, stop)) in enumerate(zip(starts, stops))
        r = start:stop
        conduction_slice = conduction[r]
        conduction_percent_sum[i_point] += sum(conduction_slice)
        conduction_percent_count[i_point] += length(r)
    end

end

mask_nonzeros = .!iszero.(conduction_percent_count)

conduction_percent_mean = zeros(size(conduction_percent_sum))
conduction_percent_mean =
    conduction_percent_sum[mask_nonzeros] ./ conduction_percent_count[mask_nonzeros]

##

folder_conduction_mean = "/media/andrey/easystore/Rheeda/activation/conduction-mean"
filename_conduction_mean =
    joinpath(folder_conduction_mean, "M$(i_heart)-G$(i_group)-conduction-mean.float64")
write(filename_conduction_mean, conduction_percent_mean)
