using ProgressMeter
using DataFrames, CSV

include("../io/read_binary.jl")
include("../ActArrays/ActArrays.jl")
include("../io/load_arrays.jl")
include("./Hist2D.jl")

##

function collect_data(
    h::Integer, g::Integer, s::Integer;
    folder_rheeda::String,
    df_fd::DataFrame,
    time_stop=2500.,
    H::Hist2D
)

    a = load_arrays(h, g, s; folder_rheeda)

    for row in eachrow(df_fd)

        fd = row.mean_fd
        v = row.i

        times = get_subarray(a, v, :times)
        conduction = get_subarray(a, v, :conduction)
        i_last = searchsortedlast(times, time_stop)

        dts = diff(times[1: i_last])
        cs = conduction[2: i_last]

        for (dt, c) in zip(dts, cs)
            isnan(c) && continue
            update_bin(fd, dt, c, H)
        end

    end

end

##

heart = 15

folder_rheeda = "/Volumes/samsung-T5/HPL/Rheeda"
folder_write = joinpath(folder_rheeda, "conduction-dt")

filename_fd = joinpath(folder_rheeda, "averaging", "M$heart-100000-latest.csv")
df_fd = CSV.read(
    filename_fd,
    DataFrame,
    select=["i", "mean_fd", "group"]
)
df_fd = df_fd[df_fd.group .== 1, Not(:group)]
sort!(df_fd, :i)

function loc(i, df; index_col=:i)
    j = searchsorted(df[!, index_col], i)
    isnothing(j) && return
    df[j, :]
end

##

groups = (1, 2, 3, 4)
stims = 0: 39

fd_bins = collect(0:0.01:1)
t_bins = collect(0:10.:1000)

# H = Hist2D(fd_bins, t_bins)
# collect_data(heart, 1, 10; folder_rheeda, df_fd, H=H)

write(
    joinpath(folder_write, "hist", "bins-x.float"),
    fd_bins
)

write(
    joinpath(folder_write, "hist", "bins-y.float"),
    t_bins
)

Threads.@threads for group in groups

    H = Hist2D(fd_bins, t_bins)

    @showprogress for stim in stims
        collect_data(heart, group, stim; folder_rheeda, df_fd, H=H)
    end

    filename_save = joinpath(folder_write, "hist", "$heart-$group-counts.int")
    write(filename_save, H.counts)

    filename_save = joinpath(folder_write, "hist", "$heart-$group-sums.float")
    write(filename_save, H.sums)

end
