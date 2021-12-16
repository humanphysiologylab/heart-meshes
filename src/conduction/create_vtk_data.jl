using ProgressMeter
using Statistics

include("../io/read_binary.jl")

i_heart = 13
i_group = 2
i_stim = string(13, pad = 2)

triplet = "M$i_heart/G$i_group/S$i_stim"
folder_root = "/media/andrey/easystore/Rheeda/activation/"

folder_data = joinpath(folder_root, "data-light", triplet)

folder_results = joinpath(folder_root, "results", triplet)

folder_vtk = joinpath(folder_root, "vtk-data", triplet)
mkpath(folder_vtk)

##

filename_times = joinpath(folder_data, "times.float32")
filename_starts = joinpath(folder_data, "indices_start.int32")

filename_conduction = joinpath(folder_results, "conduction.float32")

filenames = filename_starts, filename_times, filename_conduction
if !all(isfile.(filenames))
    @warn "incomplete root!"
end

times = read_binary(filename_times, Float32)
conduction = read_binary(filename_conduction, Float32)
n_times = length(conduction)

starts = read_binary(filename_starts, Int32)
stops = similar(starts)
@views stops[1:end-1] = starts[2:end] .- 1
stops[end] = n_times

times_save_stop = vcat([300, 580, 840, 1080, 1300], collect(1500:200:7500))

times_save_start = times_save_stop .- 500
clamp!(times_save_start, 0, 7500)

n_points = length(starts)
activation_times = zeros(Float32, n_points)
conduction_percents = zeros(Float32, n_points)

##

enum_zip = collect(enumerate(zip(times_save_start, times_save_stop)))

@showprogress for (i_save, (t_save_start, t_save_stop)) in enum_zip

    @views for (i_point, (start, stop)) in enumerate(zip(starts, stops))
        r = start:stop

        times_slice = times[r]
        conduction_slice = conduction[r]

        i_time_activated = searchsortedlast(times_slice, t_save_stop)

        if i_time_activated ≠ 0
            act_time = times_slice[i_time_activated]
            cond_precent = conduction_slice[i_time_activated]
        else
            act_time = cond_precent = NaN32
        end

        activation_times[i_point] = act_time
        conduction_percents[i_point] = cond_precent

    end


    q1, q2 = 0.1, 0.01
    activation_times_filtered = Iterators.filter(!isnan, activation_times)
    tq1, tq2 = map(q -> quantile(activation_times_filtered, q), (q1, q2))

    t_cut = tq1 - q1 * (tq2 - tq1) / (q2 - q1)
    t_cut -= 10  # ms

    activation_times[activation_times.<t_cut] .= NaN32

    # t_range = join(
    #     map(
    #         t -> string(t, pad=4),
    #         (t_save_start, t_save_stop)
    #     ),
    #      "-"
    # )

    t_range = string(t_save_stop, pad = 4)

    filename_activation = joinpath(folder_vtk, "activation-$t_range.float32")
    filename_conduction = joinpath(folder_vtk, "conduction-$t_range.float32")

    write(filename_activation, activation_times)
    write(filename_conduction, conduction_percents)

end
