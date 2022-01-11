using JSON3
using FFTW
using DataInterpolations

include("../io/read_binary.jl")
include("../misc/rolling_mean.jl")
include("../misc/pyplot.jl")

# for i_heart in heart_ids, i_group in group_ids, i_stim in stim_ids
i_heart, i_group, i_stim = 13, 3, 13

points = read_binary(
    "/media/andrey/ssd2/WORK/HPL/Data/rheeda/M$i_heart/M$(i_heart)_IRC_3Dpoints.float32",
    Float32,
    (3, :),
)

##

triplet = "M$i_heart-G$i_group-S$(string(i_stim, pad = 2))"
filename = joinpath("../../data/rotors/trajectories/", "$triplet.json")

rotors = JSON3.read(read(filename, String))

##

function create_trajectory(vertices, times, points; rolling_window = 10) 

    traj = points[:, vertices]
    
    times_interp = first(times): last(times)

    traj_interp = map(x -> LinearInterpolation(x, times).(times_interp), eachrow(traj))
    traj_smooth = map(x -> rolling_mean(x, rolling_window), traj_interp)

    traj_smooth = transpose(hcat(traj_smooth...))
    traj_interp = transpose(hcat(traj_interp...))

    times_interp_smooth = rolling_mean(times_interp, rolling_window)

    return times_interp_smooth, traj_smooth

end

##

rotor = rotors[1]

max(rotor[:times]...) - min(rotor[:times]...)

t, X = create_trajectory(rotor[:vertex_ids], rotor[:times], points, rolling_window=1)

##

function calculate_traj_length(traj)
    sum(sum(diff(X, dims=2) .^ 2, dims=1) .^ 0.5)
end

function find_dominant_period(traj)
    spectra = abs.(rfft(traj, 2)[:, 2:end])
    sp = sum(eachrow(spectra))
    fq = rfftfreq(size(traj, 2))[2:end]
    fq_max = fq[findmax(sp)[2]]  # 1 / ms
    T_max = 1 / fq_max  # ms
end

##

perimeter = calculate_traj_length(X)
CL = find_dominant_period(X)

lifetime = diff(rotor[:times][[1, end]])[1]

CV = perimeter / lifetime


##

ix, iy = 1, 3
plot(points[ix, 1:10:end], points[iy, 1:10:end], ",")
plot(X[ix, :], X[iy, :])

##

plot(X[1, :])
