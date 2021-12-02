using ProgressMeter
include("../../src/io.jl")

## 

function collect_conduction_arrays(folder::String, time_switch::AbstractFloat = 2500.0)

    n_points = nothing

    result = Dict("before" => Dict(), "after" => Dict())

    for (root, dirs, files) in walkdir(folder)

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
            continue
        end

        times = read_binary(filename_times, Float32)
        conduction = read_binary(filename_conduction, Float32)
        n_times = length(conduction)

        starts = read_binary(filename_starts, Int32)
        stops = create_stops(starts, n_times)

        if isnothing(n_points)
            n_points = length(starts)
            result["before"]["sum"] = zeros(n_points)
            result["before"]["count"] = zeros(Int, n_points)
            result["after"]["sum"] = zeros(n_points)
            result["after"]["count"] = zeros(Int, n_points)
            time_switch = convert(eltype(times), time_switch)
            @info "n_points = $n_points"
        else
            if n_points ≠ length(starts)
                @warn "n_points differs!"
                @show n_points, length(starts)
                continue
            end
        end

        @views for (i_point, (start, stop)) in enumerate(zip(starts, stops))
            index_after = searchsortedlast(times[start:stop], time_switch)
            r_before = start:start+index_after-1
            r_after = start+index_after:stop

            result["before"]["sum"][i_point] += sum(conduction[r_before])
            result["before"]["count"][i_point] += length(r_before)

            result["after"]["sum"][i_point] += sum(conduction[r_after])
            result["after"]["count"][i_point] += length(r_after)
        end

    end

    return result

end

##

##

hearts = 13, 15
groups = 4:-1:1
time_switch = 2500

folder_save = "/media/andrey/easystore/Rheeda/activation/conduction-mean"

for i_heart in hearts, i_group in groups

    folder_group_data = "/media/andrey/easystore/Rheeda/activation/data-light/M$i_heart/G$i_group"
    filename_check = "M$(i_heart)-G$(i_group)-conduction-sum-before-$time_switch-ms.float64"
    if isfile(joinpath(folder_save, filename_check))
        @warn "$filename_check exists!"
        continue
    end

    @info "Heart $i_heart, Group $i_group"
    # @info "thread: $(Threads.threadid())"

    result = collect_conduction_arrays(folder_group_data, float(time_switch))

    for time_name in ("before", "after"), array_name in ("sum", "count")

        ext = (array_name == "sum") ? "float64" : "int64"
        filename_conduction_mean = "M$(i_heart)-G$(i_group)-conduction-$array_name-$time_name-$time_switch-ms.$ext"
        filename_conduction_mean_full = joinpath(folder_save, filename_conduction_mean)
        write(filename_conduction_mean_full, result[time_name][array_name])

    end


end

##

result = collect_conduction_arrays(folder_group_data, float(time_switch))

for time_name in ("before", "after"), array_name in ("sum", "count")

    filename_conduction_mean = "M$(i_heart)-G$(i_group)-conduction-$array_name-$time_name-$(convert(Int, time_switch))-ms.float64"
    filename_conduction_mean_full = joinpath(folder_save, filename_conduction_mean)
    write(filename_conduction_mean_full, result[time_name][array_name])

end
